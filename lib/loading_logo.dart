// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingLogo extends StatelessWidget {
  final double progress;
  final double size;
  const LoadingLogo({super.key, required this.progress, this.size = 140});

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRect(
            clipper: _OutlineClipper(clamped),
            clipBehavior: Clip.antiAlias,
            child: SvgPicture.asset(
              'assets/retouched_logo_outline.svg',
              width: size,
              height: size,
            ),
          ),
          ClipRect(
            clipper: _FillClipper(clamped),
            clipBehavior: Clip.antiAlias,
            child: SvgPicture.asset(
              'assets/retouched_logo.svg',
              width: size,
              height: size,
            ),
          ),
        ],
      ),
    );
  }
}

class _FillClipper extends CustomClipper<Rect> {
  final double progress;
  _FillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, size.height * (1 - progress), size.width, size.height * progress);
  }

  @override
  bool shouldReclip(_FillClipper oldClipper) => oldClipper.progress != progress;
}

class _OutlineClipper extends CustomClipper<Rect> {
  final double progress;
  _OutlineClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height * (1 - progress));
  }

  @override
  bool shouldReclip(_OutlineClipper oldClipper) => oldClipper.progress != progress;
}
