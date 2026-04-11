// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UnlockSlider extends StatefulWidget {
  final double unlockThreshold;
  final VoidCallback onUnlocked;

  const UnlockSlider({
    super.key,
    required this.onUnlocked,
    this.unlockThreshold = 0.9,
  });

  @override
  State<UnlockSlider> createState() => UnlockSliderState();
}

class UnlockSliderState extends State<UnlockSlider> {
  static const double _bgWidth = 200;
  static const double _bgHeight = 50;
  static const double _handleSize = 56;
  static const double _maxX = _bgWidth - _handleSize;

  double _x = _maxX;
  int? _activePointer;
  double _dragOffset = 0;
  bool _active = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void nudge() {
    if (_activePointer != null) return;
    _show();
    _hideDelayed();
  }

  void _show() {
    _hideTimer?.cancel();
    setState(() => _active = true);
  }

  void _hideDelayed() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool dragging = _activePointer != null;
    return SizedBox(
      width: _bgWidth,
      height: _handleSize,
      child: Listener(
        behavior: _activePointer != null
            ? HitTestBehavior.opaque
            : HitTestBehavior.translucent,
        onPointerDown: (e) {
          if (_activePointer == null &&
              e.localPosition.dx >= _x &&
              e.localPosition.dx <= _x + _handleSize) {
            _show();
            setState(() {
              _activePointer = e.pointer;
              _dragOffset = e.localPosition.dx - _x;
            });
          }
        },
        onPointerMove: (e) {
          if (e.pointer != _activePointer) return;
          setState(() {
            _x = (e.localPosition.dx - _dragOffset).clamp(0.0, _maxX);
          });
        },
        onPointerUp: (e) {
          if (e.pointer != _activePointer) return;
          final progress = _maxX > 0 ? 1 - (_x / _maxX) : 0.0;
          setState(() {
            _activePointer = null;
            _x = _maxX;
          });
          _hideDelayed();
          if (progress >= widget.unlockThreshold) widget.onUnlocked();
        },
        onPointerCancel: (e) {
          if (e.pointer != _activePointer) return;
          setState(() {
            _activePointer = null;
            _x = _maxX;
          });
          _hideDelayed();
        },
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: (_handleSize - _bgHeight) / 2,
              child: AnimatedOpacity(
                opacity: (dragging || _active) ? 1.0 : 0.0,
                duration: (dragging || _active)
                    ? const Duration(milliseconds: 250)
                    : const Duration(milliseconds: 350),
                child: SvgPicture.asset(
                  'assets/unlock_slider_bg.svg',
                  width: _bgWidth,
                  height: _bgHeight,
                ),
              ),
            ),
            Positioned(
              left: _x,
              top: 0,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/unlock_slider.svg',
                  width: _handleSize,
                  height: _handleSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
