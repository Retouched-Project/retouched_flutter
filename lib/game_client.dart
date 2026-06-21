// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:logging/logging.dart';
import 'package:vibration/vibration.dart';
import 'server_mgr.dart';
import 'device_info.dart';
import 'bmlib/bm_lib.dart';
import 'bmrender/controls/scheme.pb.dart';
import 'bmrender/controls/scheme_extensions.dart';
import 'bmrender/controls/touch_enums.dart' show ControlTouchPoint;
import 'core/message_framer.dart';
import 'features/sensor_processor.dart';
import 'features/touch_processor.dart';
import 'features/registry_client.dart';
import 'features/capabilities.dart';
import 'utils/metrics_service.dart';

class GameClient {
  static final _log = Logger('retouched.GameClient');
  static final _wireLog = Logger('retouched.GameClient.wire');

  static const int clientPort = 9081;
  static const int udpPort = 9080;
  static const int serverPort = 8088;

  static const String serverDeviceId = 'server';
  static const String serverDeviceName = 'Registry';

  static final Uint8List _policyRequestBytes = Uint8List.fromList(
    '<policy-file-request/>\u0000'.codeUnits,
  );
  static final Uint8List _policyResponseBytes = Uint8List.fromList(
    '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="1008-49151" /></cross-domain-policy>\u0000'
        .codeUnits,
  );

  bool debugWire = true;
  final ServerEntry server;
  final BmLib _lib = BmLib.instance;
  ffi.Pointer<ffi.Void>? _engine;

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  final _registryFramer = MessageFramer();
  Socket? _gameSocket;
  StreamSubscription<List<int>>? _gameSub;
  final _gameFramer = MessageFramer();
  ServerSocket? _gameServer;
  RawDatagramSocket? _udpSocket;
  StreamSubscription<RawSocketEvent>? _udpSub;

  late final StreamController<List<String>> _gamesC =
      StreamController<List<String>>.broadcast(
        onListen: () {
          if (_registry.games.isNotEmpty) {
            scheduleMicrotask(() => _gamesC.add(_registry.games));
          }
        },
      );

  late final StreamController<double> _progressC =
      StreamController<double>.broadcast(
        onListen: () {
          if (_lastProgress != null) {
            scheduleMicrotask(() => _progressC.add(_lastProgress!));
          }
        },
      );

  late final StreamController<ControlScheme?> _schemeC =
      StreamController<ControlScheme?>.broadcast(
        onListen: () {
          if (_currentScheme != null) {
            scheduleMicrotask(() => _schemeC.add(_currentScheme));
          }
        },
      );

  final StreamController<void> _disconnectedC =
      StreamController<void>.broadcast();

  String? _deviceId;
  String? _deviceName;
  String? _appId;
  int _deviceType = DeviceTypeCodes.any;

  BmRegistryInfo? _selfInfo;
  BmRegistryInfo? _activeGame;
  double? _lastProgress;
  bool _isPaused = false;
  bool _gameHandshakeHandled = false;
  int _screenWidth = 480;
  int _screenHeight = 320;

  BmSchemeAssembler? _assembler;
  ControlScheme? _currentScheme;
  // Runtime touch-enable state from the enableTouch RPC. It is session state,
  // not scheme content, so it is re-applied to every scheme the assembler emits
  // (which carries the initial scheme's touchEnabled).
  bool? _touchEnabled;
  late final SensorProcessor _sensors;
  late final TouchProcessor _touch;
  late final RegistryClient _registry;
  late final Capabilities _capabilities;

  Stream<List<String>> get gamesStream => _gamesC.stream;
  List<String> get games => _registry.games;
  Stream<double> get progressStream => _progressC.stream;
  Stream<ControlScheme?> get schemeStream => _schemeC.stream;
  Stream<void> get disconnectedStream => _disconnectedC.stream;
  List<BmRegistryInfo> get gameInfos => _registry.gameInfos;

  GameClient(this.server) {
    _sensors = SensorProcessor(_lib);
    _sensors.getEngine = () => _engine!;
    _sensors.getActiveGameDeviceId = () => _activeGame?.deviceId;
    _sensors.sendActions = _sendOutgoings;

    _touch = TouchProcessor(_lib);
    _touch.getEngine = () => _engine!;
    _touch.getActiveGameDeviceId = () => _activeGame?.deviceId;
    _touch.sendActions = _sendOutgoings;

    _registry = RegistryClient(_lib);
    _registry.getEngine = () => _engine!;
    _registry.onGamesChanged = (games) {
      _gamesC.add(games);
    };

    _capabilities = Capabilities();
  }

  void setCapabilitiesOverride(int? mask) {
    _capabilities.setOverride(mask);
  }

  Future<void> connect({Duration timeout = const Duration(seconds: 5)}) async {
    _lib.init();
    _registry.registerCompleter = Completer<void>();
    _registry.listCompleter = Completer<void>();

    try {
      _socket = await Socket.connect(server.ip, serverPort, timeout: timeout);
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _sub = _socket!.listen(
        _onData,
        onError: (e) {
          _safeCompleteError(_registry.registerCompleter, e);
          _safeComplete(_registry.listCompleter);
        },
        onDone: _onDone,
      );

      _engine = _lib.createEngine();
      _assembler = _lib.createSchemeAssembler();
      await _initIdentity();

      final localHost = await _determineLocalHost();
      _lib.initLocalDevice(
        _engine!,
        _deviceId!,
        _deviceName!,
        _deviceType,
        localHost,
        udpPort,
        clientPort,
      );

      _lib.registerDevice(
        _engine!,
        serverDeviceId,
        serverDeviceName,
        DeviceTypeCodes.server,
        server.ip,
        0,
        serverPort,
      );

      await _bindGameListeners();

      final ver = _lib.handshakeBytes();
      _socket!.add(ver);
      await _socket!.flush();

      await _sendRegistration(localHost);
      await _waitForRegister(timeout: timeout);

      await requestList();
      _capabilities.get();
    } catch (_) {
      await close();
      rethrow;
    }
  }

  Future<String> _determineLocalHost() async {
    final override = server.localIp?.trim();
    if (override != null && override.isNotEmpty && override != '0.0.0.0') {
      return override;
    }
    final local = _socket?.address.address;
    if (local != null &&
        local.isNotEmpty &&
        local != '0.0.0.0' &&
        local != server.ip) {
      return local;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final serverParts = server.ip.split('.');
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.isEmpty || ip.startsWith('169.254.')) continue;
          if (serverParts.length == 4) {
            final parts = ip.split('.');
            if (parts.length == 4 &&
                parts[0] == serverParts[0] &&
                parts[1] == serverParts[1] &&
                parts[2] == serverParts[2]) {
              return ip;
            }
          }
        }
      }
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.isNotEmpty && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (_) {}
    return local ?? '0.0.0.0';
  }

  Future<void> requestList() async {
    final actions = _lib.makeRegistryList(_engine!, serverDeviceId);
    _sendOutgoings(actions);
  }

  Future<List<String>> waitForList(Duration timeout) async {
    if (_registry.games.isNotEmpty) return _registry.games;
    _registry.listCompleter ??= Completer<void>();
    final timer = Timer(timeout, () => _safeComplete(_registry.listCompleter));
    await _registry.listCompleter!.future;
    timer.cancel();
    return _registry.games;
  }

  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
    await _udpSub?.cancel();
    _udpSub = null;
    _udpSocket?.close();
    _udpSocket = null;
    await _gameSub?.cancel();
    _gameSub = null;
    await _gameSocket?.close();
    _gameSocket = null;
    await _gameServer?.close();
    _gameServer = null;
    _sensors.stopAll();
    _touch.cancel();
    _registryFramer.clear();
    _gameFramer.clear();
    if (_engine != null) {
      _lib.freeEngine(_engine!);
      _engine = null;
    }
    _assembler?.dispose();
    _assembler = null;
    if (!_gamesC.isClosed) {
      await _gamesC.close();
    }
    if (!_progressC.isClosed) {
      await _progressC.close();
    }
    if (!_schemeC.isClosed) {
      await _schemeC.close();
    }
    if (!_disconnectedC.isClosed) {
      await _disconnectedC.close();
    }
  }

  Future<void> _initIdentity() async {
    if (_deviceId != null) return;
    _deviceId = DeviceInfo.generateDeviceId();
    _appId = DeviceInfo.generateAppId();
    _deviceType = DeviceInfo.platformDeviceTypeCode();
    _deviceName = await DeviceInfo().getDeviceName();
  }

  Future<void> _sendRegistration(String localHost) async {
    final info = BmRegistryInfo(
      slotId: 0,
      appId: _appId ?? 'retouched',
      currentPlayers: 0,
      maxPlayers: 0,
      deviceType: _deviceType,
      deviceId: _deviceId ?? '',
      deviceName: _deviceName ?? 'Unknown',
      address: localHost,
      unreliablePort: udpPort,
      reliablePort: clientPort,
    );
    _selfInfo = info;
    final actions = _lib.makeRegistryRegister(
      _engine!,
      serverDeviceId,
      info,
      'retouchedflutter',
    );
    _sendOutgoings(actions);
  }

  void _onData(List<int> data) {
    final frames = _registryFramer.feed(data);
    for (final frame in frames) {
      if (debugWire) _logHex('RX frame', frame);
      _handleOutput(_lib.processIncoming(_engine!, frame));
    }
  }

  void _onUdpEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _udpSocket?.receive();
    if (dg == null) return;
    _handleOutput(_lib.processIncomingUdp(_engine!, dg.data));
  }

  void _onGameData(List<int> data) {
    if (_handlePolicyRequest(data)) return;
    final frames = _gameFramer.feed(data);
    for (final frame in frames) {
      if (debugWire) _logHex('RX frame', frame);
      _handleOutput(_lib.processIncoming(_engine!, frame));
    }
  }

  void _onDone() {
    _safeCompleteError(
      _registry.registerCompleter,
      const SocketException('Connection closed by server'),
    );
    _safeComplete(_registry.listCompleter);
    _socket = null;
    _sub = null;
    _registry.reset();
    if (!_gamesC.isClosed) {
      _gamesC.add(const []);
    }
    if (!_disconnectedC.isClosed) {
      _disconnectedC.add(null);
    }
  }

  void _onGameDone() {
    if (_isHandlingPolicy) {
      _isHandlingPolicy = false;
      final sub = _gameSub;
      _gameSub = null;
      _gameSocket = null;
      _gameFramer.clear();
      if (sub != null) unawaited(sub.cancel());
      return;
    }

    if (_activeGame != null) {
      MetricsService.send(
        type: MetricsService.sessionEnd,
        appId: _activeGame!.appId,
        serverIp: server.ip,
        deviceId: _deviceId ?? '',
      );
    }
    _activeGame = null;
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
    final sub = _gameSub;
    _gameSub = null;
    _gameSocket = null;
    _gameFramer.clear();
    if (sub != null) unawaited(sub.cancel());
  }

  void _handleOutput(BmProcessOutput output) {
    _sendOutgoings(output.outgoings);
    for (final event in output.events) {
      _handleEvent(event);
    }
  }

  void _handleEvent(BmEvent event) {
    switch (event.type) {
      case 'Handshake':
        _handleHandshake(event);
        break;
      case 'RegistrationResult':
        _registry.onRegistrationResult();
        break;
      case 'HostList':
        _registry.onHostList(event.infos);
        break;
      case 'HostConnected':
      case 'HostUpdated':
        _registry.onHostUpsert(event.info);
        break;
      case 'HostDisconnected':
        _registry.onHostDisconnected(event.info);
        break;
      case 'ControlConfig':
        _handleControlConfig(event);
        break;
      case 'ChunkProgress':
        _handleChunkProgress(event);
        break;
      case 'ChunkComplete':
        _handleChunkComplete(event);
        break;
      case 'Vibrate':
        _doVibrate();
        break;
      case 'Invoke':
        _handleInvoke(event);
        break;
      default:
        if (debugWire) {
          _log.fine('Unhandled event: ${event.type}');
        }
        break;
    }
  }

  void _handleHandshake(BmEvent event) {
    if (debugWire) {
      _log.fine(
        'Handshake event received: current=${event.current}, minimum=${event.minimum}',
      );
    }
    if (_activeGame != null && !_gameHandshakeHandled) {
      _gameHandshakeHandled = true;
      _doGameInitSequence();
    }
  }

  void _handleInvoke(BmEvent invoke) {
    switch (invoke.method) {
      case 'vibrate':
        _doVibrate();
        break;
      default:
        if (debugWire) {
          _log.warning('Unhandled invoke: ${invoke.method}');
        }
        break;
    }
  }

  Future<void> _doVibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(duration: 1000);
    }
  }

  void _handleControlConfig(BmEvent cfg) {
    if (cfg.touchEnabled != null) {
      enableTouch(cfg.touchEnabled!);
    }
    if (cfg.touchIntervalMs != null) {
      _touch.touchIntervalMs = cfg.touchIntervalMs!;
    }
    if (cfg.accelEnabled != null) {
      _sensors.enableAccelerometer(cfg.accelEnabled!);
    }
    if (cfg.gyroEnabled != null) {
      _sensors.enableGyro(cfg.gyroEnabled!);
    }
    if (cfg.orientationEnabled != null) {
      enableOrientation(cfg.orientationEnabled!);
    }
    if (cfg.orientationIntervalMs != null) {
      _sensors.setOrientationIntervalMs(cfg.orientationIntervalMs!);
    }
    if (cfg.accelIntervalMs != null) {
      _sensors.setAccelIntervalMs(cfg.accelIntervalMs!);
    }
    if (cfg.gyroIntervalMs != null) {
      _sensors.setGyroIntervalMs(cfg.gyroIntervalMs!);
    }
  }

  Future<void> _waitForRegister({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _registry.registerCompleter ??= Completer<void>();
    final timer = Timer(
      timeout,
      () => _safeCompleteError(
        _registry.registerCompleter,
        TimeoutException('Server did not respond in time', timeout),
      ),
    );
    try {
      await _registry.registerCompleter!.future;
    } finally {
      timer.cancel();
    }
  }

  void _handleChunkProgress(BmEvent action) {
    if (action.total <= 0) return;
    final progress = action.current / action.total;
    _lastProgress = progress.clamp(0.0, 1.0);
    _progressC.add(_lastProgress!);
  }

  void _handleChunkComplete(BmEvent action) {
    final assembler = _assembler;
    if (assembler == null) return;
    final result = assembler.offer(action.setId, action.blob);
    if (!result.isUpdated || result.scheme == null) return;
    final scheme = ControlScheme.fromBuffer(result.scheme!);
    // Re-apply the runtime touch-enable state; the assembler carries the
    // initial scheme's touchEnabled, which would otherwise revert it.
    if (_touchEnabled != null) {
      scheme.touchEnabled = _touchEnabled!;
    }
    _currentScheme = scheme;
    if (result.initial) {
      final game = _activeGame;
      if (game != null) {
        _sendOutgoings(_lib.makeOnControlSchemeParsed(_engine!, game.deviceId));
      }
      if (scheme.isAccelerometerEnabled()) {
        _sensors.startAccel();
      }
    }
    _schemeC.add(scheme);
  }

  void handleButton(String handler, bool pressed) {
    final game = _activeGame;
    if (game == null) return;
    final actions = _lib.makeButtonInvoke(
      _engine!,
      game.deviceId,
      handler,
      pressed,
    );
    _sendOutgoings(actions);
  }

  void handleDpad(int x, int y) {
    final game = _activeGame;
    if (game == null) return;
    final actions = _lib.makeDpadUpdate(_engine!, game.deviceId, x, y);
    _sendOutgoings(actions);
  }

  void handleTouchSet(
    List<ControlTouchPoint> touches,
    int screenWidth,
    int screenHeight,
  ) {
    _touch.handleTouchSet(touches, screenWidth, screenHeight);
  }

  void setScreenSize(int width, int height) {
    if (width > 0 && height > 0) {
      _screenWidth = width;
      _screenHeight = height;
    }
  }

  void enableTouch(bool enabled) {
    if (debugWire) {
      _log.fine('enableTouch: $enabled');
    }
    _touchEnabled = enabled;
    if (_currentScheme != null) {
      _currentScheme!.touchEnabled = enabled;
      _schemeC.add(_currentScheme);
    }
  }

  void enableAccelerometer(bool enabled) {
    _sensors.enableAccelerometer(enabled);
  }

  void enableGyro(bool enabled) {
    _sensors.enableGyro(enabled);
  }

  void enableOrientation(bool enabled) {
    _sensors.setOrientationEnabled(enabled);
  }

  void setOrientationIntervalMs(int ms) {
    _sensors.setOrientationIntervalMs(ms);
  }

  void _forgetGameSession() {
    _assembler?.reset();
    _currentScheme = null;
    _touchEnabled = null;
    _gameHandshakeHandled = false;
    _sensors.reset();
    _touch.reset();
  }

  Future<void> connectToGame(BmRegistryInfo game) async {
    _activeGame = game;
    _isPaused = false;
    if (_selfInfo == null) return;
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
    await _listenForGame();
    final actions = _lib.makeDeviceConnectRequested(
      _engine!,
      serverDeviceId,
      game,
      _selfInfo!,
    );
    _sendOutgoings(actions);
    MetricsService.send(
      type: MetricsService.sessionStart,
      appId: game.appId,
      serverIp: server.ip,
      deviceId: _deviceId ?? '',
    );
  }

  ServerSocket? _policyServer;

  Future<void> _listenForGame() async {
    await _gameSub?.cancel();
    _gameSub = null;
    await _gameSocket?.close();
    _gameSocket = null;
    _gameFramer.clear();
  }

  Future<void> _bindGameListeners() async {
    try {
      if (_policyServer == null) {
        _policyServer = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          9010,
          shared: true,
        );
        _policyServer!.listen((socket) {
          socket.setOption(SocketOption.tcpNoDelay, true);
          List<int> buffer = [];
          StreamSubscription? sub;
          sub = socket.listen(
            (data) {
              buffer.addAll(data);
              if (buffer.length >= 23) {
                socket.add(_policyResponseBytes);
                socket.flush().then((_) {
                  sub?.cancel();
                  socket.close().catchError((_) {});
                });
              }
            },
            onError: (e) {
              sub?.cancel();
              socket.destroy();
            },
            onDone: () {
              sub?.cancel();
              socket.destroy();
            },
          );
        });
        _log.info('Dedicated policy server listening on port 9010');
      }
    } catch (e) {
      _log.warning('Could not bind dedicated policy port 9010: $e');
    }

    _gameServer = await ServerSocket.bind(InternetAddress.anyIPv4, clientPort);
    _gameServer!.listen((socket) {
      if (_engine == null) {
        socket.destroy();
        return;
      }
      final staleSub = _gameSub;
      final staleSocket = _gameSocket;
      _gameSub = null;
      _gameFramer.clear();
      _policyBuffer.clear();
      _isHandlingPolicy = false;
      if (staleSub != null) unawaited(staleSub.cancel());
      if (staleSocket != null) unawaited(staleSocket.close());
      socket.setOption(SocketOption.tcpNoDelay, true);
      _gameSocket = socket;
      _gameSub = socket.listen(
        _onGameData,
        onError: (_) {},
        onDone: _onGameDone,
      );
    });
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
    _udpSub = _udpSocket!.listen(_onUdpEvent);
  }

  Future<void> _doGameInitSequence() async {
    final socket = _gameSocket;
    final game = _activeGame;
    if (socket == null || game == null || _deviceId == null) return;
    await _sendHandshakeToGame(socket);
    final caps = await _capabilities.get();
    if (_activeGame == null) return;
    final capActions = _lib.makeSetCapabilities(_engine!, game.deviceId, caps);
    _sendOutgoings(capActions);
    final xmlActions = _lib.makeRequestXml(
      _engine!,
      game.deviceId,
      _screenWidth,
      _screenHeight,
    );
    _sendOutgoings(xmlActions);
  }

  Future<void> _sendHandshakeToGame(Socket socket) async {
    final ver = _lib.handshakeBytes();
    socket.add(ver);
    await socket.flush();
  }

  void sendPause() {
    _setPaused(true);
  }

  void sendResume() {
    _setPaused(false);
  }

  void _setPaused(bool pause) {
    final game = _activeGame;
    if (game == null || _isPaused == pause) return;
    _isPaused = pause;
    final actions = _lib.makePause(_engine!, game.deviceId);
    _sendOutgoings(actions);
  }

  void sendMenuEvent(String event) {
    final game = _activeGame;
    if (game == null) return;
    final actions = _lib.makeMenuEvent(_engine!, game.deviceId, event);
    _sendOutgoings(actions);
  }

  Future<void> disconnectGame() async {
    if (_activeGame != null) {
      MetricsService.send(
        type: MetricsService.sessionEnd,
        appId: _activeGame!.appId,
        serverIp: server.ip,
        deviceId: _deviceId ?? '',
      );
    }
    _activeGame = null;
    await _gameSub?.cancel();
    _gameSub = null;
    await _gameSocket?.close();
    _gameSocket = null;
    _gameFramer.clear();
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
  }

  void _sendOutgoings(List<BmOutgoing> outgoings) {
    for (final outgoing in outgoings) {
      if (debugWire) _logHex('TX frame', outgoing.payload);
      final game = _activeGame;
      if (outgoing.reliability == 0 &&
          game != null &&
          game.unreliablePort != 0 &&
          outgoing.targetDeviceId == game.deviceId &&
          _udpSocket != null) {
        _sendUdp(outgoing.payload.sublist(4));
      } else {
        final socket = _resolveSocket(outgoing.targetDeviceId);
        socket?.add(outgoing.payload);
      }
    }
  }

  void _sendUdp(Uint8List payload) {
    final game = _activeGame;
    if (game == null || _udpSocket == null) return;
    final target = InternetAddress.tryParse(game.address);
    if (target == null) return;
    _udpSocket!.send(payload, target, game.unreliablePort);
  }

  Socket? _resolveSocket(String targetDeviceId) {
    if (targetDeviceId == serverDeviceId) return _socket;
    if (_activeGame != null && targetDeviceId == _activeGame!.deviceId) {
      return _gameSocket ?? _socket;
    }
    return _socket;
  }

  bool _isHandlingPolicy = false;
  final List<int> _policyBuffer = [];

  bool _handlePolicyRequest(List<int> data) {
    if (data.isEmpty) return false;
    if (data[0] == 0x3C || _policyBuffer.isNotEmpty) {
      _policyBuffer.addAll(data);
      if (_policyBuffer.length >= _policyRequestBytes.length) {
        final socket = _gameSocket;
        if (socket != null) {
          socket.add(_policyResponseBytes);
          socket
              .flush()
              .catchError((_) {})
              .then((_) => socket.close().catchError((_) {}));
        }
        _isHandlingPolicy = true;
        _policyBuffer.clear();
        _gameFramer.clear();
      }
      return true;
    }
    return false;
  }

  void _logHex(String tag, Uint8List data) {
    final sb = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      if (i > 0) sb.write(' ');
      sb.write(data[i].toRadixString(16).padLeft(2, '0'));
    }
    _wireLog.fine('$tag (${data.length} bytes): $sb');
  }

  static void _safeComplete(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  static void _safeCompleteError(Completer<void>? completer, Object error) {
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }
}
