// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:ffi' as ffi;
import '../bmlib/bm_lib.dart';
import '../bmrender/controls/touch_enums.dart' show ControlTouchPoint;

class TouchProcessor {
  final BmLib _lib;

  final Map<int, ControlTouchPoint> _pendingTouches = {};
  Timer? _touchFlushTimer;
  int _pendingScreenW = 0;
  int _pendingScreenH = 0;
  int _lastTouchSentAt = 0;
  int touchIntervalMs = 100;
  int touchReliability = 0;

  ffi.Pointer<ffi.Void> Function()? getEngine;
  String? Function()? getActiveGameDeviceId;
  void Function(List<BmAction>)? sendActions;

  TouchProcessor(this._lib);

  void handleTouchSet(
    List<ControlTouchPoint> touches,
    int screenWidth,
    int screenHeight,
  ) {
    if (getActiveGameDeviceId?.call() == null) return;

    _pendingScreenW = screenWidth;
    _pendingScreenH = screenHeight;
    for (final t in touches) {
      _pendingTouches[t.id] = t;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final halfInterval = touchIntervalMs ~/ 2;
    final nextFlushAt = _lastTouchSentAt + halfInterval;

    if (now >= nextFlushAt) {
      _touchFlushTimer?.cancel();
      _touchFlushTimer = null;
      _flushTouches(0);
    } else if (_touchFlushTimer == null || !_touchFlushTimer!.isActive) {
      final delayMs = nextFlushAt - now;
      _touchFlushTimer = Timer(
        Duration(milliseconds: delayMs.clamp(1, touchIntervalMs)),
        () => _flushTouches(0),
      );
    }
  }

  void _flushTouches([int retryCount = 0]) {
    _touchFlushTimer?.cancel();
    _touchFlushTimer = null;
    final gameDeviceId = getActiveGameDeviceId?.call();
    if (gameDeviceId == null || _pendingTouches.isEmpty) return;

    _lastTouchSentAt = DateTime.now().millisecondsSinceEpoch;
    final points = _pendingTouches.values
        .map(
          (t) => TouchPointData(
            id: t.id,
            x: t.x,
            y: t.y,
            screenWidth: _pendingScreenW,
            screenHeight: _pendingScreenH,
            state: t.state,
          ),
        )
        .toList(growable: false);

    _pendingTouches.removeWhere((_, t) => t.state == 4 || t.state == 5);

    for (final key in _pendingTouches.keys) {
      final t = _pendingTouches[key]!;
      if (t.state == 1 || t.state == 2) {
        _pendingTouches[key] = ControlTouchPoint(
          id: t.id,
          x: t.x,
          y: t.y,
          state: 3,
        );
      }
    }

    final actions = _lib.makeTouchSet(
      getEngine!(),
      gameDeviceId,
      points,
      touchReliability,
    );
    sendActions?.call(actions);

    if (retryCount < 3 &&
        touchReliability == 0 &&
        _touchFlushTimer == null &&
        _pendingTouches.isNotEmpty) {
      _touchFlushTimer = Timer(
        Duration(milliseconds: touchIntervalMs),
        () => _flushTouches(retryCount + 1),
      );
    }
  }

  void cancel() {
    _touchFlushTimer?.cancel();
    _touchFlushTimer = null;
    _pendingTouches.clear();
  }
}
