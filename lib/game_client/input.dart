// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

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
    _log.fine('enableTouch: $enabled');
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
}
