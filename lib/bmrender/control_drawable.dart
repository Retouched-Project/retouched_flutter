// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';

abstract class ControlDrawable {
  void draw(Canvas canvas);
  Rect getBounds();
  bool isDisabled();
  int getZOrder();
  void resetState();
}
