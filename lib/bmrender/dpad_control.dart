// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:math';
import 'dart:ui';
import 'controls/sampling_mode.dart';
import 'control_drawable.dart';
import 'hit_target.dart';
import 'bitmap_control_drawable.dart';
import 'dpad_skin.dart';

class DpadControl implements ControlDrawable, HitTarget {
  static const List<int> _polarIndex = [
    3,
    6,
    6,
    7,
    7,
    8,
    8,
    5,
    5,
    2,
    2,
    1,
    1,
    0,
    0,
    3,
    3,
  ];

  final BitmapControlDrawable _frameDrawable = BitmapControlDrawable();
  DpadSkin? _skin;
  void Function(int x, int y)? onDpadUpdate;

  double _deadzoneRatio = 0.25;
  int _stateIndex = 4;

  Rect _requestedBounds = Rect.zero;
  Rect _hitBounds = Rect.zero;
  Rect _innerBounds = Rect.zero;
  Rect _deadzoneBounds = Rect.zero;
  Rect _dirtyBounds = Rect.zero;

  double _aspectYScale = 1.0;
  final bool _radialMode = true;
  bool _allowDrag = true;

  Offset _center = Offset.zero;

  DpadControl(int zOrder) {
    _frameDrawable.setZOrder(zOrder);
  }

  @override
  int getZOrder() => _frameDrawable.getZOrder();

  @override
  void draw(Canvas canvas) {
    _frameDrawable.draw(canvas);
  }

  @override
  Rect getBounds() => _frameDrawable.getBounds();

  double _radiusThreshold() {
    return getBounds().width * _deadzoneRatio * 0.5;
  }

  void _applyBounds(Rect rect) {
    _frameDrawable.setBounds(rect);
    _innerBounds = rect;
    _deadzoneBounds = rect;

    double f = 0.33333334;
    double dx = (_innerBounds.width * (1.0 - f)) / 2.0;
    double dy = (_innerBounds.height * (1.0 - f)) / 2.0;
    _innerBounds = Rect.fromLTRB(
      _innerBounds.left + dx,
      _innerBounds.top + dy,
      _innerBounds.right - dx,
      _innerBounds.bottom - dy,
    );

    f = _deadzoneRatio;
    dx = (_deadzoneBounds.width * (1.0 - f)) / 2.0;
    dy = (_deadzoneBounds.height * (1.0 - f)) / 2.0;
    _deadzoneBounds = Rect.fromLTRB(
      _deadzoneBounds.left + dx,
      _deadzoneBounds.top + dy,
      _deadzoneBounds.right - dx,
      _deadzoneBounds.bottom - dy,
    );

    _center = rect.center;
  }

  void setBounds(Rect rect, {bool preserveDrag = true}) {
    if (!preserveDrag || _requestedBounds == Rect.zero) {
      _requestedBounds = rect;
      _applyBounds(rect);
    } else {
      Offset dragOffset = getBounds().topLeft - _requestedBounds.topLeft;
      _requestedBounds = rect;
      _applyBounds(rect.shift(dragOffset));
    }
  }

  @override
  bool isDisabled() => _frameDrawable.isDisabled();

  void setDisabled(bool disabled) {
    _frameDrawable.setDisabled(disabled);
  }

  void setAllowDrag(bool allow) {
    _allowDrag = allow;
  }

  @override
  void resetState() {
    _frameDrawable.resetState();
    _updateState(4);
  }

  void setSkin(DpadSkin skin) {
    _skin = skin;
    _frameDrawable.setBitmap(skin.getFrame(_stateIndex));
  }

  @override
  bool hitTest(Offset point) {
    return _hitBounds.contains(point);
  }

  void setHitRect(Rect rect) {
    _hitBounds = rect;
  }

  static int _band(double v, double minV, double maxV) {
    if (v < minV) return 0;
    if (v < maxV) return 1;
    return 2;
  }

  static int _gridIndex(Offset p, Rect r) {
    return _band(p.dx, r.left, r.right) + (_band(p.dy, r.top, r.bottom) * 3);
  }

  @override
  Rect getHitBounds() => _dirtyBounds;

  int _stateIndexFromCartesian(Offset p) {
    return _innerBounds.contains(p)
        ? _gridIndex(p, _deadzoneBounds)
        : _gridIndex(p, _innerBounds);
  }

  int _stateIndexFromRadial(Offset p) {
    double ox = p.dx - _center.dx;
    double oy = (p.dy - _center.dy) * _aspectYScale;

    if (sqrt(ox * ox + oy * oy) < _radiusThreshold()) {
      return 4;
    }

    double angle = atan2(-oy, ox) + pi;
    int idx = (angle / 0.39269908169872414).floor(); // pi/8
    return _polarIndex[idx.clamp(0, _polarIndex.length - 1)];
  }

  int _computeState(Offset? p) {
    if (p == null) return 4;
    if (_radialMode) return _stateIndexFromRadial(p);
    return _stateIndexFromCartesian(p);
  }

  void setAspectRatio(double scale) {
    _aspectYScale = scale;
  }

  double _minRadius() {
    return getBounds().width / 2.0;
  }

  Rect _getClampedRect(Rect rect) {
    double dx = 0;
    double dy = 0;
    if (rect.left < _hitBounds.left) {
      dx = _hitBounds.left - rect.left;
    } else if (rect.right > _hitBounds.right) {
      dx = _hitBounds.right - rect.right;
    }

    if (rect.top < _hitBounds.top) {
      dy = _hitBounds.top - rect.top;
    } else if (rect.bottom > _hitBounds.bottom) {
      dy = _hitBounds.bottom - rect.bottom;
    }

    return rect.shift(Offset(dx, dy));
  }

  bool _applyDrag(Offset? p) {
    if (p == null) return false;

    double ox = p.dx - _center.dx;
    double oy = p.dy - _center.dy;
    double oyScaled = oy * _aspectYScale;

    double minR = _minRadius();
    double len = sqrt(ox * ox + oyScaled * oyScaled);

    if (len <= minR) return false;

    double f = (len - minR) / len;
    ox *= f;
    oy = (f / _aspectYScale) * oyScaled;

    Rect bounds = _frameDrawable.getBounds();
    bounds = bounds.shift(Offset(ox, oy));
    bounds = _getClampedRect(bounds);

    _applyBounds(bounds);
    _dirtyBounds = _dirtyBounds.expandToInclude(bounds);
    return true;
  }

  @override
  bool handleHit(Offset? point) {
    bool stateChanged = _updateState(_computeState(point));
    _dirtyBounds = getBounds();
    if (_allowDrag) {
      return stateChanged | _applyDrag(point);
    }
    return stateChanged;
  }

  void setDeadzone(double ratio) {
    _deadzoneRatio = ratio;
  }

  void setSampling(SamplingMode mode) {
    _frameDrawable.setFilter(mode);
  }

  bool _updateState(int i) {
    if (i == _stateIndex) return false;
    _stateIndex = i;
    _updateBitmap();
    _sendDpadUpdate();
    return true;
  }

  void _sendDpadUpdate() {
    onDpadUpdate?.call((_stateIndex % 3) - 1, (_stateIndex ~/ 3) - 1);
  }

  void _updateBitmap() {
    if (_skin != null) {
      _frameDrawable.setBitmap(_skin!.getFrame(_stateIndex));
    }
  }
}
