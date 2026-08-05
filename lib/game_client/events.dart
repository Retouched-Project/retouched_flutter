// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientEvents on GameClient {
  void _handleOutput(BmProcessOutput output) {
    _sendOutgoings(output.outgoings);
    for (final event in output.events) {
      _handleEvent(event);
    }
  }

  void _handleEvent(BmEvent event) {
    switch (event.type) {
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
      case 'PeerConnected':
        _handlePeerConnected(event);
        break;
      case 'ConnectionFailed':
        _handleConnectionFailed(event);
        break;
      default:
        _log.finest('Unhandled event: ${event.type}');
        break;
    }
  }

  void _handlePeerConnected(BmEvent event) {
    final game = _activeGame;
    final socket = _gameSocket;
    if (game == null || socket == null || event.peerDeviceId != game.deviceId) {
      return;
    }
    final gameIp = socket.remoteAddress.address;
    _activeGame = game.withEndpoint(
      address: gameIp,
      unreliablePort: event.peerUnreliablePort,
      reliablePort: game.reliablePort,
    );
    _log.info('Ack set UDP endpoint: $gameIp:${event.peerUnreliablePort}');
  }

  void _handleConnectionFailed(BmEvent event) {
    final failed = event.deviceId;
    _log.warning('Game reported connection failed: $failed');
    if (failed.isNotEmpty && failed == _activeGame?.deviceId) {
      unawaited(disconnectGame());
    }
  }

  void _handleInvoke(BmEvent invoke) {
    switch (invoke.method) {
      case 'vibrate':
        _doVibrate();
        break;
      default:
        _log.warning('Unhandled invoke: ${invoke.method}');
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
    if (cfg.controlMode != null) {
      // startString is the keyboard's initial text; only KEYBOARD mode sends it.
      _lastControlConfig = GameControlConfig(
        cfg.controlMode!,
        cfg.startString ?? '',
      );
      _controlConfigC.add(_lastControlConfig!);
    }
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
}
