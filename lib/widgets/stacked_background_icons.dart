// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StackedBackgroundIcons extends StatelessWidget {
  const StackedBackgroundIcons({
    super.key,
    required this.connected,
    required this.hasGames,
  });

  final bool connected;
  final bool hasGames;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _badgedIcon('assets/server.svg', positive: connected),
              const SizedBox(height: 16),
              _badgedIcon('assets/host.svg', positive: hasGames),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgedIcon(String mainAsset, {required bool positive}) {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 110,
            height: 110,
            child: SvgPicture.asset(mainAsset),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: 72,
            height: 72,
            child: SvgPicture.asset(
              positive ? 'assets/checkmark.svg' : 'assets/cross.svg',
            ),
          ),
        ],
      ),
    );
  }
}
