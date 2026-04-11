// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui';
import 'package:logging/logging.dart';
import 'controls/sampling_mode.dart';
import 'control_drawable.dart';
import 'hit_target.dart';
import 'bitmap_control_drawable.dart';
import 'selection_controller.dart';

class ToggleControl implements ControlDrawable, HitTarget {
  static final _log = Logger('retouched.ToggleControl');
  SelectionController? controller;
  int zOrder;
  String? _id;
  String? get handlerId => _id;
  final BitmapControlDrawable _upDrawable;
  final BitmapControlDrawable _downDrawable;

  void setDebugNames(String name) {
    _upDrawable.debugName = '$name-UP';
    _downDrawable.debugName = '$name-DOWN';
  }

  bool _active = false;
  bool get isActive => _active;
  bool _disabled = false;
  Rect _hitRect = Rect.zero;

  ToggleControl(this.zOrder, this._upDrawable, this._downDrawable);

  @override
  bool hitTest(Offset point) {
    return _hitRect.contains(point);
  }

  void setHitRect(Rect rect) {
    _hitRect = rect;
  }

  bool _hasLoggedDebug = false;
  @override
  void draw(Canvas canvas) {
    if (_active || !_hasLoggedDebug) {
      final upBmp = _upDrawable.bitmap;
      final downBmp = _downDrawable.bitmap;
      if (zOrder > 0) {
        _log.fine(
          'ToggleControl $zOrder: Active=$_active, Bounds=${getBounds()}, '
          'UpBitmap=${upBmp?.width}x${upBmp?.height}, DownBitmap=${downBmp?.width}x${downBmp?.height}',
        );
        if (!_active) {
          _hasLoggedDebug =
              true;
        }
      }
    }
    _currentDrawable().draw(canvas);
  }

  ControlDrawable _currentDrawable() {
    return _active ? _downDrawable : _upDrawable;
  }

  @override
  Rect getBounds() {
    return _currentDrawable().getBounds();
  }

  @override
  bool handleHit(Offset? point) {
    return setActive(point != null);
  }

  bool setActive(bool active) {
    if (active != _active) {
      _active = active;
      if (_active) {
        controller?.onSelected(_id ?? '');
      } else {
        controller?.onDeselected(_id ?? '');
      }
      return true;
    }
    return false;
  }

  void deactivate() {
    setActive(false);
  }

  @override
  bool isDisabled() => _disabled;

  void setDisabled(bool disabled) {
    _disabled = disabled;
  }

  @override
  Rect getHitBounds() => getBounds();

  @override
  int getZOrder() => zOrder;

  void setBounds(Rect rect) {
    _upDrawable.setBounds(rect);
    _downDrawable.setBounds(rect);
  }

  void setTint(SamplingMode mode) {
    _upDrawable.setFilter(mode);
    _downDrawable.setFilter(mode);
  }

  void setId(String? id) {
    if ((id == null && _id != null) || (id != null && id != _id)) {
      if (_active) {
        controller?.onDeselected(_id ?? '');
        controller?.onSelected(id ?? '');
      }
      _id = id;
    }
  }

  void setUpBitmap(Image? bitmap) {
    _upDrawable.setBitmap(bitmap);
  }

  void setDownBitmap(Image? bitmap) {
    _downDrawable.setBitmap(bitmap);
  }

  @override
  void resetState() {
    deactivate();
  }
}
