// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';
import 'package:logging/logging.dart';
import 'controls/sampling_mode.dart';
import 'control_drawable.dart';

class BitmapControlDrawable implements ControlDrawable {
  static final _log = Logger('retouched.BitmapControlDrawable');
  Image? _bitmap;
  Rect _bounds = Rect.zero;
  int _zOrder = 0;
  bool _disabled = false;
  final Paint _paint = Paint();

  String? debugName;
  bool _hasLogged = false;

  BitmapControlDrawable([this._bitmap]);

  Image? get bitmap => _bitmap;

  @override
  void draw(Canvas canvas) {
    if (_bitmap != null) {
      if (!_hasLogged && debugName != null) {
        _log.fine(
          'Drawing $debugName: Bounds=$_bounds, Bitmap=${_bitmap!.width}x${_bitmap!.height}, Z=$_zOrder',
        );
        _hasLogged = true;
      }
      final src = Rect.fromLTWH(
        0,
        0,
        _bitmap!.width.toDouble(),
        _bitmap!.height.toDouble(),
      );
      canvas.drawImageRect(_bitmap!, src, _bounds, _paint);
    } else {
      if (!_hasLogged && debugName != null) {
        _log.warning(
          'Drawing $debugName: Bounds=$_bounds, BITMAP IS NULL, Z=$_zOrder',
        );
        _hasLogged = true;
      }
    }
  }

  void setBitmap(Image? bitmap) {
    if (bitmap != _bitmap) {
      _bitmap = bitmap;
    }
  }

  void setFilter(SamplingMode mode) {
    if (mode == SamplingMode.bilinear) {
      _paint.filterQuality = FilterQuality.low;
    } else {
      _paint.filterQuality = FilterQuality.none;
    }
  }

  @override
  int getZOrder() => _zOrder;

  void setZOrder(int z) {
    _zOrder = z;
  }

  @override
  bool isDisabled() => _disabled;

  void setDisabled(bool disabled) {
    _disabled = disabled;
  }

  @override
  Rect getBounds() => _bounds;

  void setBounds(Rect rect) {
    _bounds = rect;
  }

  @override
  void resetState() {}
}
