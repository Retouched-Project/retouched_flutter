// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

class TouchStateCodes {
  static const int began = 1;
  static const int moved = 2;
  static const int stationary = 3;
  static const int ended = 4;
  static const int cancelled = 5;
}

class ControlTouchPoint {
  final int id;
  final double x;
  final double y;
  final int state;

  const ControlTouchPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.state,
  });
}