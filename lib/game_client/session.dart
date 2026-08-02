// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientSession on GameClient {
  void _forgetGameSession() {
    _assembler?.reset();
    _currentScheme = null;
    _touchEnabled = null;
    _lastControlConfig = null;
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

  Future<void> _listenForGame() async {
    await _gameSub?.cancel();
    _gameSub = null;
    await _gameSocket?.close();
    _gameSocket = null;
    _gameFramer.reset();
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
      _gameFramer.reset();
      _policyBuffer.clear();
      _isHandlingPolicy = false;
      _policySniffArmed = true;
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
    _gameFramer.reset();
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
  }
}
