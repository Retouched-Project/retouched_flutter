// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientSession on GameClient {
  void _forgetGameSession() {
    _udpConfirmed = false;
    _udpWarned = false;
    _assembler?.reset();
    _currentScheme = null;
    _lastControlConfig = null;
    _lastProgress = null;
    if (!_progressC.isClosed) {
      _progressC.add(0.0);
    }
    _sensors.reset();
    _stopEngineTimer();
    _forgetQueuedTouches();
  }

  Future<void> connectToGame(BmRegistryInfo game) async {
    _activeGame = game;
    _isPaused = false;
    if (_selfInfo == null) return;
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
    await _closeGameLink();
    final actions = _lib.makeDeviceConnectRequested(
      _engine!,
      serverDeviceId,
      game.deviceId,
    );
    _sendOutgoings(actions);
    MetricsService.send(
      type: MetricsService.sessionStart,
      appId: game.appId,
      serverIp: server.ip,
      httpPort: server.httpPort,
      deviceId: _deviceId ?? '',
    );
  }

  Future<void> _closeGameLink() async {
    final sub = _gameSub;
    final socket = _gameSocket;
    _gameSub = null;
    _gameSocket = null;
    _gameFramer.reset();
    _gameHandshakerInst?.reset();
    await sub?.cancel();
    await socket?.close();
  }

  Future<void> _teardownGame() async {
    final game = _activeGame;
    if (game != null) {
      MetricsService.send(
        type: MetricsService.sessionEnd,
        appId: game.appId,
        serverIp: server.ip,
        httpPort: server.httpPort,
        deviceId: _deviceId ?? '',
      );
      // The engine must be told the peer is gone,
      // otherwise it would keep holding it
      _tellEnginePeerGone(game.deviceId);
    }
    _activeGame = null;
    _forgetGameSession();
    if (!_schemeC.isClosed) {
      _schemeC.add(null);
    }
    await _closeGameLink();
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
          // Nothing but policy requests reach this port, but a request can
          // still arrive in pieces, so the sniffer decides when it is whole.
          final sniffer = _lib.createPolicySniffer();
          StreamSubscription? sub;
          sub = socket.listen(
            (data) {
              if (sniffer.feed(data).kind != PolicySniffKind.answer) return;
              socket.add(_lib.policyResponse);
              socket.flush().then((_) {
                sub?.cancel();
                sniffer.dispose();
                socket.close().catchError((_) {});
              });
            },
            onError: (e) {
              sub?.cancel();
              sniffer.dispose();
              socket.destroy();
            },
            onDone: () {
              sub?.cancel();
              sniffer.dispose();
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
      unawaited(_closeGameLink());
      // Every connection is watched from its first byte, and only there.
      _gamePolicySniffer.reset();
      socket.setOption(SocketOption.tcpNoDelay, true);
      _gameSocket = socket;
      _gameSub = socket.listen(
        _onGameData,
        // A reset ends the session as surely as a clean close, and waiting
        // for a done that may not follow leaves the engine holding a peer.
        onError: (_) => _onGameDone(),
        onDone: _onGameDone,
      );
    });
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
    _udpSub = _udpSocket!.listen(_onUdpEvent);
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

  Future<void> disconnectGame() => _teardownGame();
}
