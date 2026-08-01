// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';

class DpadSkin {
  static const List<String> frameNames = [
    'left_up',
    'up',
    'right_up',
    'left',
    'inactive',
    'right',
    'left_down',
    'down',
    'right_down',
  ];

  final List<ui.Image?> _frames = List.filled(9, null);

  void setFrame(int idx, ui.Image? bitmap) {
    if (idx >= 0 && idx < 9) {
      _frames[idx] = bitmap;
    }
  }

  ui.Image? getFrame(int idx) {
    if (idx >= 0 && idx < 9) {
      return _frames[idx];
    }
    return null;
  }

  static const int builtInFrameSize = 512;
  static DpadSkin? _builtIn;
  static Future<DpadSkin>? _builtInLoading;

  static DpadSkin? builtInOrNull() => _builtIn;

  static Future<DpadSkin> loadBuiltIn() {
    final cached = _builtIn;
    if (cached != null) return Future.value(cached);
    // Clearing the pending future on failure keeps one bad load from poisoning
    // every later scheme that needs the built-in skin.
    return _builtInLoading ??= _rasterizeBuiltIn().then(
      (skin) {
        _builtIn = skin;
        _builtInLoading = null;
        return skin;
      },
      onError: (Object e, StackTrace st) {
        _builtInLoading = null;
        Error.throwWithStackTrace(e, st);
      },
    );
  }

  static Future<DpadSkin> _rasterizeBuiltIn() async {
    final skin = DpadSkin();
    for (int i = 0; i < frameNames.length; i++) {
      final loader = SvgAssetLoader('assets/dpad/dpad_${frameNames[i]}.svg');
      final info = await vg.loadPicture(loader, null);
      // The loaded picture is drawn in the SVG's viewBox coordinate space, so it
      // must be scaled to fill the frame.
      final size = info.size;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (size.width > 0 && size.height > 0) {
        canvas.scale(
          builtInFrameSize / size.width,
          builtInFrameSize / size.height,
        );
      }
      canvas.drawPicture(info.picture);
      final picture = recorder.endRecording();
      final image = await picture.toImage(builtInFrameSize, builtInFrameSize);
      info.picture.dispose();
      picture.dispose();
      skin.setFrame(i, image);
    }
    return skin;
  }
}
