// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'controls/scheme.pb.dart';
import 'controls/scheme_extensions.dart';
import 'controls/control_orientation.dart';
import 'control_drawable.dart';
import 'hit_target.dart';
import 'control_view_builder.dart';
import 'selection_controller.dart';
import 'controls/touch_enums.dart' show ControlTouchPoint, TouchStateCodes;

class BMRenderView extends StatefulWidget {
  final ControlScheme scheme;
  final void Function(String handler, bool pressed)? onButton;
  final void Function(int x, int y)? onDpad;
  final void Function(
    List<ControlTouchPoint> touches,
    int screenWidth,
    int screenHeight,
  )?
  onTouchSet;
  final bool floatingDpadEnabled;
  final bool smartWidescreenEnabled;
  final bool preserveDpadDragEnabled;
  // Forces the rotated (portrait) presentation for whitelisted games that
  // declared landscape but authored a portrait scheme.
  final bool forceRotate;

  const BMRenderView({
    super.key,
    required this.scheme,
    this.onButton,
    this.onDpad,
    this.onTouchSet,
    this.floatingDpadEnabled = true,
    this.smartWidescreenEnabled = false,
    this.preserveDpadDragEnabled = false,
    this.forceRotate = false,
  });

  @override
  State<BMRenderView> createState() => _BMRenderViewState();
}

class _BMRenderViewState extends State<BMRenderView>
    implements SelectionController {
  static final _log = Logger('retouched.BMRenderView');

  final Map<int, ControlTouchPoint> _touches = {};
  final Map<int, Offset> _pointerPositions = {};

  late ControlViewBuilder _builder;
  List<ControlDrawable> _controls = [];
  List<HitTarget> _hitTargets = [];

  final Set<String> _activeButtons = {};

  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  double _baseW = 320.0;
  double _baseH = 480.0;
  bool _rotated = false;

  ControlScheme? _pendingScheme;
  final Set<int> _pendingChanged = {};
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    _builder = ControlViewBuilder(
      selectionController: this,
      onDpadUpdate: widget.onDpad,
      floatDpadEnabled: widget.floatingDpadEnabled,
      preserveDpadDragEnabled: widget.preserveDpadDragEnabled,
    );
    _enqueueScheme(widget.scheme);
  }

  @override
  void didUpdateWidget(BMRenderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scheme != oldWidget.scheme) {
      _enqueueScheme(widget.scheme);
    }
  }

  @override
  void dispose() {
    _builder.recycle();
    super.dispose();
  }

  @override
  void onSelected(String id) {
    if (!_activeButtons.contains(id)) {
      _activeButtons.add(id);
      widget.onButton?.call(id, true);
    }
  }

  @override
  void onDeselected(String id) {
    if (_activeButtons.contains(id)) {
      _activeButtons.remove(id);
      widget.onButton?.call(id, false);
    }
  }

  void _enqueueScheme(ControlScheme scheme) {
    // Every scheme carries the complete merged state, so a newer one fully
    // supersedes anything still waiting to be applied. The changed ids are the
    // exception: they describe one update each, so a superseded scheme's ids
    // still have to be decoded and are folded in rather than dropped.
    _pendingScheme = scheme;
    _pendingChanged.addAll(scheme.changedResources);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return; // already draining
    _isProcessingQueue = true;
    try {
      while (_pendingScheme != null) {
        final scheme = _pendingScheme!;
        final changed = Set<int>.of(_pendingChanged);
        _pendingScheme = null;
        _pendingChanged.clear();
        try {
          // Decoding happens off-frame; the swap below is synchronous so no
          // half-applied scheme is ever painted.
          final decoded = await _builder.decodeResources(scheme, changed);
          if (!mounted) {
            for (final img in decoded.values) {
              img.dispose();
            }
            return;
          }

          final oldImages = _builder.applyResources(decoded);
          _updateControls(scheme);
          for (final img in oldImages) {
            img.dispose();
          }
        } catch (e, st) {
          // Nothing was applied, so these ids still need decoding whenever the
          // next scheme arrives.
          _pendingChanged.addAll(changed);
          _log.warning('Applying control scheme failed: $e');
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: e,
              stack: st,
              library: 'retouched_flutter',
              context: ErrorDescription('applying a control scheme'),
            ),
          );
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  void _updateControls(ControlScheme scheme) {
    _baseW = scheme.getWidth().toDouble();
    _baseH = scheme.getHeight().toDouble();

    if (_baseW <= 0 || _baseH <= 0) {
      if (scheme.getRotation() == ControlOrientation.landscape) {
        _baseW = 480.0;
        _baseH = 320.0;
      } else {
        _baseW = 320.0;
        _baseH = 480.0;
      }
    }

    _rotated = false;
    if (scheme.getRotation() == ControlOrientation.landscape &&
        (_baseW < _baseH || widget.forceRotate)) {
      _rotated = true;
      // Only swap when the declared dimensions are portrait-shaped.
      // A whitelisted (forceRotate) scheme already carries landscape dimensions.
      if (_baseW < _baseH) {
        final temp = _baseW;
        _baseW = _baseH;
        _baseH = temp;
      }
    }

    ControlScheme effectiveScheme = scheme;
    bool widescreenStretched = false;

    if (widget.smartWidescreenEnabled &&
        !_rotated &&
        scheme.getRotation() == ControlOrientation.landscape &&
        _baseW <= 480 &&
        scheme.getDisplayObjects().any((o) => o.getType() == 'dpad')) {
      final screenSize = MediaQuery.of(context).size;
      final longSide = max(screenSize.width, screenSize.height);
      final shortSide = min(screenSize.width, screenSize.height);
      final screenAspect = longSide / shortSide;
      final targetW = min(320.0 * screenAspect, 568.0);

      if (targetW > _baseW) {
        final newScheme = scheme.deepCopy();
        final extraW = targetW - _baseW;

        for (final obj in newScheme.getDisplayObjects()) {
          if (!obj.hasLeft() || !obj.hasWidth()) continue;

          if (obj.width > 0.95) {
            continue;
          }

          final oldPixelL = obj.left * _baseW;
          final oldPixelW = obj.width * _baseW;
          final oldCenterX = oldPixelL + (oldPixelW / 2);

          double newPixelL = oldPixelL;

          if (oldCenterX > _baseW * 0.55) {
            newPixelL += extraW;
          } else if (oldCenterX > _baseW * 0.45) {
            newPixelL += extraW / 2;
          }

          obj.left = newPixelL / targetW;
          obj.width = oldPixelW / targetW;

          if (obj.hasHitRect) {
            final oldPixelHitL = obj.hitLeft * _baseW;
            final oldPixelHitW = obj.hitWidth * _baseW;

            double offset = 0.0;
            if (oldCenterX > _baseW * 0.55) {
              offset = extraW;
            } else if (oldCenterX > _baseW * 0.45) {
              offset = extraW / 2;
            }

            obj.hitLeft = (oldPixelHitL + offset) / targetW;
            obj.hitWidth = oldPixelHitW / targetW;
          }
        }

        _baseW = targetW;
        effectiveScheme = newScheme;
        widescreenStretched = true;
      }
    }

    _controls = _builder.update(
      effectiveScheme,
      _controls,
      _baseW,
      _baseH,
      widescreenStretched,
    );

    var newHitTargets = <HitTarget>[];
    for (final c in _controls) {
      if (c is HitTarget) {
        newHitTargets.add(c as HitTarget);
      }
    }

    newHitTargets = newHitTargets.reversed.toList();

    _hitTargets = newHitTargets;

    final newHandlers = scheme
        .getDisplayObjects()
        .map((o) => o.getFunctionHandler())
        .where((h) => h != null && h.isNotEmpty)
        .toSet();

    final removedHandlers = <String>{};
    _activeButtons.removeWhere((id) {
      if (!newHandlers.contains(id)) {
        removedHandlers.add(id);
        return true;
      }
      return false;
    });

    for (final id in removedHandlers) {
      widget.onButton?.call(id, false);
    }

    // A layout swap can invalidate active hit targets even when no pointer has
    // moved, so reconcile the full set rather than only newly hit targets.
    _recalculateHits();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;

        if (availW <= 0 || availH <= 0) return const SizedBox.shrink();

        // When rotated, the content's width/height swap on screen, so fit and
        // center against the swapped dimensions.
        if (_rotated) {
          _scale = min(availW / _baseH, availH / _baseW);
          _offsetX = (availW - _baseH * _scale) / 2;
          _offsetY = (availH - _baseW * _scale) / 2;
        } else {
          _scale = min(availW / _baseW, availH / _baseH);
          _offsetX = (availW - _baseW * _scale) / 2;
          _offsetY = (availH - _baseH * _scale) / 2;
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: CustomPaint(
            size: Size(availW, availH),
            painter: _BMPainter(
              controls: _controls,
              scale: _scale,
              offsetX: _offsetX,
              offsetY: _offsetY,
              baseW: _baseW,
              baseH: _baseH,
              rotated: _rotated,
            ),
          ),
        );
      },
    );
  }

  Offset _toSchemeCoords(Offset pos) {
    // Inverse of _BMPainter's transform.
    if (_rotated) {
      final cx = (pos.dy - _offsetY) / _scale;
      final cy = _baseH - (pos.dx - _offsetX) / _scale;
      return Offset(cx, cy);
    }
    final x = (pos.dx - _offsetX) / _scale;
    final y = (pos.dy - _offsetY) / _scale;
    return Offset(x, y);
  }

  void _handlePointerDown(PointerDownEvent e) {
    final pos = _toSchemeCoords(e.localPosition);
    _pointerPositions[e.pointer] = pos;
    _recalculateHits();
    _handleTouchEvent(e.pointer, pos, TouchStateCodes.began);
  }

  void _handlePointerMove(PointerMoveEvent e) {
    final pos = _toSchemeCoords(e.localPosition);
    _pointerPositions[e.pointer] = pos;
    _recalculateHits();
    _handleTouchEvent(e.pointer, pos, TouchStateCodes.moved);
  }

  void _handlePointerUp(PointerUpEvent e) {
    final pos = _toSchemeCoords(e.localPosition);
    _pointerPositions.remove(e.pointer);
    _recalculateHits();
    _handleTouchEvent(e.pointer, pos, TouchStateCodes.ended);
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    final pos = _toSchemeCoords(e.localPosition);
    _pointerPositions.remove(e.pointer);
    _recalculateHits();
    _handleTouchEvent(e.pointer, pos, TouchStateCodes.cancelled);
  }

  void _handleTouchEvent(int id, Offset pos, int state) {
    if (!widget.scheme.isTouchEnabled() || widget.onTouchSet == null) return;
    _touches[id] = ControlTouchPoint(
      id: id,
      x: pos.dx,
      y: pos.dy,
      state: state,
    );
    final touches = _touches.values.toList(growable: false);

    int w = widget.scheme.getWidth();
    int h = widget.scheme.getHeight();
    if (w <= 0) w = _rotated ? _baseH.round() : _baseW.round();
    if (h <= 0) h = _rotated ? _baseW.round() : _baseH.round();

    widget.onTouchSet?.call(touches, w, h);

    if (state == TouchStateCodes.ended || state == TouchStateCodes.cancelled) {
      _touches.remove(id);
    } else if (state == TouchStateCodes.moved) {
      _touches[id] = ControlTouchPoint(
        id: id,
        x: pos.dx,
        y: pos.dy,
        state: TouchStateCodes.stationary,
      );
    }
  }

  void _recalculateHits() {
    bool needsRepaint = false;

    for (final target in _hitTargets) {
      Offset? hitPoint;
      // Hidden controls are not pressable, and one that becomes hidden while
      // held has to be released rather than left active.
      if (!target.isDisabled()) {
        for (final pos in _pointerPositions.values) {
          if (target.hitTest(pos)) {
            hitPoint = pos;
            break;
          }
        }
      }

      if (target.handleHit(hitPoint)) needsRepaint = true;
    }

    if (needsRepaint) setState(() {});
  }
}

class _BMPainter extends CustomPainter {
  final List<ControlDrawable> controls;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double baseW;
  final double baseH;
  final bool rotated;

  _BMPainter({
    required this.controls,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.baseW,
    required this.baseH,
    required this.rotated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (rotated) {
      // Maps content point (cx, cy) -> (offsetX + (baseH - cy)*scale,
      // offsetY + cx*scale): a 90deg turn fitted to the swapped footprint.
      canvas.translate(offsetX + baseH * scale, offsetY);
      canvas.rotate(pi / 2);
      canvas.scale(scale, scale);
    } else {
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale, scale);
    }

    for (final c in controls) {
      if (!c.isDisabled()) {
        c.draw(canvas);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BMPainter oldDelegate) {
    return true;
  }
}
