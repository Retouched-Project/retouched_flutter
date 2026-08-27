// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

/// Stationary has no entry: the engine reaches it once a set has gone, and the
/// renderer never reports it.
const Map<int, BmTouchPhase> _touchPhases = {
  TouchStateCodes.began: BmTouchPhase.began,
  TouchStateCodes.moved: BmTouchPhase.moved,
  TouchStateCodes.ended: BmTouchPhase.ended,
  TouchStateCodes.cancelled: BmTouchPhase.cancelled,
};

extension GameClientInput on GameClient {
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

  void sendKeyString(String key) {
    final game = _activeGame;
    if (game == null) return;
    final actions = _lib.makeSendKeyString(_engine!, game.deviceId, key);
    _sendOutgoings(actions);
  }

  void sendNavigation(String nav) {
    final game = _activeGame;
    if (game == null) return;
    final actions = _lib.makeSendNavigation(_engine!, game.deviceId, nav);
    _sendOutgoings(actions);
  }

  void handleTouchEvent(
    ControlTouchPoint touch,
    int screenWidth,
    int screenHeight,
  ) {
    final phase = _touchPhases[touch.state];
    if (_activeGame == null || phase == null) return;

    _touchQueue.add(
      BmPointerEvent(
        id: touch.id,
        x: touch.x,
        y: touch.y,
        phase: phase,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
    );

    // Offering these before the engine would take them only to be told no
    // costs a crossing per finger per frame, so they wait for the moment it
    // named. What they add up to is worked out there, not here.
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = _touchSendDueAt;
    if (due == null || now >= due) {
      _shipTouches(now);
    } else {
      _armEngineTimer(due);
    }
  }

  void _shipTouches(int nowMs) {
    final game = _activeGame;
    if (game == null || _touchQueue.isEmpty) return;

    final events = List<BmTouchEvent>.of(_touchQueue);
    _touchQueue.clear();
    final out = _lib.makeTouchEvents(_engine!, game.deviceId, events, nowMs);
    _touchSendDueAt = out.nextSendMs;
    _sendOutgoings(out.outgoings);
    _armEngineTimer(out.nextTimeMs);
  }

  void setScreenSize(int width, int height) {
    if (width > 0 && height > 0) {
      _screenWidth = width;
      _screenHeight = height;
    }
  }

  void enableTouch(bool enabled) {
    _log.fine('enableTouch: $enabled');
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
}
