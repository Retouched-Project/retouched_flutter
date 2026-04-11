// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

// This class is used for the widescreen hack.
// It stretches the middle of the background of games that send non-widescreen dpad views.
// It splits the bitmap into 3 slices to avoid distorting buttons.

import 'dart:ui';
import 'controls/sampling_mode.dart';
import 'control_drawable.dart';

class SlicedBitmapControlDrawable implements ControlDrawable {
  Image? _bitmap;
  Rect _bounds = Rect.zero;
  int _zOrder = 0;
  bool _disabled = false;
  final Paint _paint = Paint();

  String? debugName;

  static const double _splitL = 0.45;
  static const double _splitR = 0.55;

  SlicedBitmapControlDrawable([this._bitmap]);

  @override
  void draw(Canvas canvas) {
    if (_bitmap != null) {
      final srcW = _bitmap!.width.toDouble();
      final srcH = _bitmap!.height.toDouble();
      final dstW = _bounds.width;
      final dstH = _bounds.height;

      final srcX1 = srcW * _splitL;
      final srcX2 = srcW * _splitR;

      final scaleY = dstH / srcH;
      final dstX1 = srcX1 * scaleY;

      final rightPanelW = (srcW - srcX2) * scaleY;
      final dstX2 = dstW - rightPanelW;

      _drawSlice(
        canvas,
        Rect.fromLTRB(0, 0, srcX1, srcH),
        Rect.fromLTRB(
          _bounds.left,
          _bounds.top,
          _bounds.left + dstX1,
          _bounds.bottom,
        ),
      );

      _drawSlice(
        canvas,
        Rect.fromLTRB(srcX1, 0, srcX2, srcH),
        Rect.fromLTRB(
          _bounds.left + dstX1,
          _bounds.top,
          _bounds.left + dstX2,
          _bounds.bottom,
        ),
      );

      _drawSlice(
        canvas,
        Rect.fromLTRB(srcX2, 0, srcW, srcH),
        Rect.fromLTRB(
          _bounds.left + dstX2,
          _bounds.top,
          _bounds.right,
          _bounds.bottom,
        ),
      );
    }
  }

  void _drawSlice(Canvas canvas, Rect src, Rect dst) {
    canvas.drawImageRect(_bitmap!, src, dst, _paint);
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
