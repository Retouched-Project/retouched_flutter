// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';

abstract class HitTarget {
  bool hitTest(Offset point);
  bool handleHit(Offset? point);
  bool isDisabled();
  Rect getHitBounds();
}
