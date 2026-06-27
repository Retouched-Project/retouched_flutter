// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:logging/logging.dart';
import 'package:vibration/vibration.dart';
import '../utils/server_mgr.dart';
import '../utils/device_info.dart';
import '../bmlib/bm_lib.dart';
import '../bmrender/controls/scheme.pb.dart';
import '../bmrender/controls/scheme_extensions.dart';
import '../bmrender/controls/touch_enums.dart' show ControlTouchPoint;
import '../core/message_framer.dart';
import '../features/sensor_processor.dart';
import '../features/touch_processor.dart';
import '../features/registry_client.dart';
import '../features/capabilities.dart';
import '../utils/metrics_service.dart';

part 'connection.dart';
part 'events.dart';
part 'input.dart';
part 'session.dart';
part 'transport.dart';

final _log = Logger('retouched.GameClient');
final _wireLog = Logger('retouched.GameClient.wire');

const int clientPort = 9081;
const int udpPort = 9080;
const int serverPort = 8088;

const String serverDeviceId = 'server';
const String serverDeviceName = 'Registry';

final Uint8List _policyRequestBytes = Uint8List.fromList(
  '<policy-file-request/>\u0000'.codeUnits,
);
final Uint8List _policyResponseBytes = Uint8List.fromList(
  '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="1008-49151" /></cross-domain-policy>\u0000'
      .codeUnits,
);

void _safeComplete(Completer<void>? completer) {
  if (completer != null && !completer.isCompleted) {
    completer.complete();
  }
}

void _safeCompleteError(Completer<void>? completer, Object error) {
  if (completer != null && !completer.isCompleted) {
    completer.completeError(error);
  }
}

class GameClient {
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
  ServerSocket? _policyServer;
  bool _isHandlingPolicy = false;
  final List<int> _policyBuffer = [];

  Stream<List<String>> get gamesStream => _gamesC.stream;
  List<String> get games => _registry.games;
  Stream<double> get progressStream => _progressC.stream;
  Stream<ControlScheme?> get schemeStream => _schemeC.stream;
  Stream<void> get disconnectedStream => _disconnectedC.stream;
  List<BmRegistryInfo> get gameInfos => _registry.gameInfos;
  String? get activeGameAppId => _activeGame?.appId;

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
}
