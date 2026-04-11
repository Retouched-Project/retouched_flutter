// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';

class DpadSkin {
  static const List<String> frameNames = [
    'left_up', 'up', 'right_up',
    'left', 'inactive', 'right',
    'left_down', 'down', 'right_down'
  ];

  final List<Image?> _frames = List.filled(9, null);

  void setFrame(int idx, Image? bitmap) {
    if (idx >= 0 && idx < 9) {
      _frames[idx] = bitmap;
    }
  }

  Image? getFrame(int idx) {
    if (idx >= 0 && idx < 9) {
      return _frames[idx];
    }
    return null;
  }
}
