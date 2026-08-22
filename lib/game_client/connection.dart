// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientConnection on GameClient {
  void setCapabilitiesOverride(int? mask) {
    _capabilities.setOverride(mask);
    _capabilities.get().then(_applySessionInputs);
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
      _applySessionInputs(0);

      _lib.declarePeer(
        _engine!,
        serverDeviceId,
        serverDeviceName,
        DeviceTypeCodes.server,
        server.ip,
        0,
        serverPort,
      );

      await _bindGameListeners();

      await _sendRegistration(localHost);
      await _waitForRegister(timeout: timeout);

      await requestList();
      _capabilities.get().then(_applySessionInputs);
    } catch (_) {
      await close();
      rethrow;
    }
  }

  /// The engine opens game sessions from these, so it needs them before a game
  /// connects. Sensor probing finishes later than that can be, so it is handed
  /// what is known and told again when the probe lands.
  void _applySessionInputs(int capabilities) {
    if (_engine == null) return;
    _lib.configure(
      _engine!,
      endpoint: EndpointMode.controller,
      gyroscope: (capabilities & 1) != 0,
      orientation: (capabilities & 2) != 0,
      screenWidth: _screenWidth,
      screenHeight: _screenHeight,
      datagrams: true,
    );
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
    _registryFramerInst?.dispose();
    _registryFramerInst = null;
    _gameFramerInst?.dispose();
    _gameFramerInst = null;
    _registryHandshakerInst?.dispose();
    _registryHandshakerInst = null;
    _gameHandshakerInst?.dispose();
    _gameHandshakerInst = null;
    _gamePolicySnifferInst?.dispose();
    _gamePolicySnifferInst = null;
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
    if (!_controlConfigC.isClosed) {
      await _controlConfigC.close();
    }
    if (!_disconnectedC.isClosed) {
      await _disconnectedC.close();
    }
  }

  Future<void> _initIdentity() async {
    if (_deviceId != null) return;
    _deviceId = _lib.generateDeviceId();
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
    final List<Uint8List> frames;
    try {
      frames = _registryFramer.feed(data);
    } on BmFramingException catch (e) {
      _log.severe('Registry stream out of step: $e');
      _onDone();
      return;
    }
    for (final frame in frames) {
      final outcome = _registryHandshaker.onMessage(frame);
      if (outcome.passthrough) {
        _handleOutput(
          _lib.processIncoming(
            _engine!,
            frame,
            source: _socket?.remoteAddress.address,
          ),
        );
        continue;
      }
      _answerHandshake(outcome, _socket, 'Registry');
    }
  }

  /// A responder answers the version exchange and never opens it.
  void _answerHandshake(HandshakeOutcome outcome, Socket? socket, String who) {
    final reply = outcome.reply;
    if (reply != null && socket != null) {
      socket.add(_lib.frame(reply));
    }
    if (!outcome.compatible) {
      _log.severe('$who version is not compatible: ${outcome.check}');
    }
  }

  void _onUdpEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _udpSocket?.receive();
    if (dg == null) return;
    // A datagram is already one whole message, so it needs no framer.
    _handleOutput(
      _lib.processIncoming(
        _engine!,
        dg.data,
        source: dg.address.address,
        sourcePort: dg.port,
        datagram: true,
      ),
    );
  }

  void _onGameData(List<int> data) {
    final payload = _filterPolicyRequest(data);
    if (payload == null) return;
    final List<Uint8List> frames;
    try {
      frames = _gameFramer.feed(payload);
    } on BmFramingException catch (e) {
      _log.severe('Game stream out of step: $e');
      _onGameDone();
      return;
    }
    for (final frame in frames) {
      final outcome = _gameHandshaker.onMessage(frame);
      if (outcome.passthrough) {
        _handleOutput(
          _lib.processIncoming(
            _engine!,
            frame,
            source: _gameSocket?.remoteAddress.address,
          ),
        );
        continue;
      }
      _answerHandshake(outcome, _gameSocket, 'Game');
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
    if (_gamePolicySnifferInst?.hungUp() ?? false) {
      final sub = _gameSub;
      _gameSub = null;
      _gameSocket = null;
      _gameFramer.reset();
      _gameHandshakerInst?.reset();
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
    _gameFramer.reset();
    _gameHandshakerInst?.reset();
    if (sub != null) unawaited(sub.cancel());
  }
}
