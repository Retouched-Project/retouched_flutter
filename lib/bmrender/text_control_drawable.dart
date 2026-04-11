// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';
import 'package:flutter/painting.dart' as painting;
import 'control_drawable.dart';

class TextControlDrawable implements ControlDrawable {
  final int _zOrder;
  Rect _bounds = Rect.zero;
  String _text = '';
  bool _disabled = false;
  Color _color = const Color(0xFFFFFFFF);
  double _textSize = 12.0;

  TextControlDrawable(this._zOrder);

  @override
  int getZOrder() => _zOrder;

  @override
  void draw(Canvas canvas) {
    final textStyle = painting.TextStyle(
      color: _color,
      fontSize: _textSize,
    );
    final textSpan = painting.TextSpan(text: _text, style: textStyle);
    final textPainter = painting.TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    textPainter.layout(minWidth: 0, maxWidth: _bounds.width);
    textPainter.paint(canvas, Offset(_bounds.left, _bounds.bottom - textPainter.height));
  }

  @override
  Rect getBounds() => _bounds;

  void setBounds(Rect rect) {
    _bounds = rect;
  }

  @override
  bool isDisabled() => _disabled;

  void setDisabled(bool disabled) {
    _disabled = disabled;
  }

  @override
  void resetState() {}

  void setText(String? text) {
    _text = text ?? '';
  }

  void setColor(int? color) {
    if (color != null) {
      _color = Color(0xFF000000 | color);
    } else {
      _color = const Color(0xFFFFFFFF);
    }
  }

  void setTextSize(double? size) {
    if (size != null) {
      _textSize = size;
    }
  }
}
