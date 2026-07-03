// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WaitOverlay extends StatelessWidget {
  const WaitOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/wait.svg', width: 64, height: 64),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for Game',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
