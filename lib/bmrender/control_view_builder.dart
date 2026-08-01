// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'controls/scheme.pb.dart';
import 'controls/scheme_extensions.dart';
import 'dpad_skin.dart';
import 'control_drawable.dart';
import 'bitmap_control_drawable.dart';
import 'text_control_drawable.dart';
import 'toggle_control.dart';
import 'dpad_control.dart';
import 'selection_controller.dart';

import 'sliced_bitmap_control_drawable.dart';

class ControlViewBuilder {
  static final _log = Logger('retouched.ControlViewBuilder');
  final SelectionController selectionController;
  final void Function(int x, int y)? onDpadUpdate;
  final bool floatDpadEnabled;
  final bool preserveDpadDragEnabled;

  final Map<int, ui.Image> _bitmapCache = {};
  final Map<int, DpadControl> _dpadCache = {};

  ControlViewBuilder({
    required this.selectionController,
    this.onDpadUpdate,
    this.floatDpadEnabled = true,
    this.preserveDpadDragEnabled = false,
  });

  // A merged scheme carries every resource it has ever seen, not just the ones
  // that changed, so [changed] is what says which bitmaps are actually new. An
  // id missing from the cache is decoded regardless of that, which covers both
  // a fresh builder and a retry after a failed decode.
  Future<Map<int, ui.Image>> decodeResources(
    ControlScheme scheme,
    Set<int> changed,
  ) async {
    final resources = scheme.getResources();
    _log.fine('Decoding resources: ${resources.length} resources.');

    final futures = <Future<MapEntry<int, ui.Image>?>>[];
    var reused = 0;
    for (final res in resources) {
      final id = res.getId();
      final data = res.getBitmap();
      if (data == null || data.isEmpty) continue;
      if (!changed.contains(id) && _bitmapCache.containsKey(id)) {
        reused++;
        continue;
      }
      futures.add(() async {
        try {
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          codec.dispose();
          return MapEntry(id, frame.image);
        } catch (e) {
          _log.warning('Error decoding resource $id: $e');
          return null;
        }
      }());
    }

    final results = await Future.wait(futures);
    final Map<int, ui.Image> staging = {};
    for (final entry in results) {
      if (entry != null) staging[entry.key] = entry.value;
    }
    _log.fine(
      'Decoded ${staging.length} resources, reused $reused cached resources.',
    );

    final needsBuiltInDpad = scheme.getDisplayObjects().any(
      (o) => o.getType() == 'dpad' && !o.hasAssets(),
    );
    if (needsBuiltInDpad) {
      await DpadSkin.loadBuiltIn();
    }

    return staging;
  }

  // Swaps decoded images into the cache and returns the ones they displaced,
  // for the caller to dispose once the new scheme is on screen.
  List<ui.Image> applyResources(Map<int, ui.Image> decoded) {
    final List<ui.Image> replaced = [];
    decoded.forEach((id, image) {
      final old = _bitmapCache[id];
      if (old != null) replaced.add(old);
      _bitmapCache[id] = image;
    });
    return replaced;
  }

  List<ControlDrawable> update(
    ControlScheme scheme,
    List<ControlDrawable> currentControls,
    double baseW,
    double baseH,
    bool widescreenStretched,
  ) {
    final List<ControlDrawable> newControls = [];
    final Map<int, ControlDrawable> inactive = {};
    final Map<String, ToggleControl> inactiveByHandler = {};

    for (final c in currentControls) {
      inactive[c.getZOrder()] = c;
      if (c is ToggleControl &&
          c.handlerId != null &&
          c.handlerId!.isNotEmpty) {
        inactiveByHandler[c.handlerId!] = c;
      }
    }

    for (final obj in scheme.getDisplayObjects()) {
      ControlDrawable? existing = inactive[obj.getId()];

      if (existing == null) {
        final handler = obj.getFunctionHandler();
        if (handler != null && handler.isNotEmpty) {
          final handlerMatch = inactiveByHandler[handler];
          if (handlerMatch != null) {
            existing = handlerMatch;
            inactive.remove(handlerMatch.getZOrder());
            inactiveByHandler.remove(handler);
          }
        }
      }

      ControlDrawable? newControl;

      if (obj.getType() == 'button') {
        newControl = _updateButton(obj, existing, baseW, baseH);
      } else if (obj.getType() == 'image') {
        newControl = _updateImage(
          obj,
          existing,
          baseW,
          baseH,
          widescreenStretched,
        );
      } else if (obj.getType() == 'text') {
        newControl = _updateText(obj, existing, baseW, baseH);
      } else if (obj.getType() == 'dpad') {
        newControl = _updateDpad(obj, existing, baseW, baseH);
      } else if (obj.getFunctionHandler() != null &&
          obj.getFunctionHandler()!.isNotEmpty) {
        newControl = _updateButton(obj, existing, baseW, baseH);
      } else {
        newControl = _updateImage(
          obj,
          existing,
          baseW,
          baseH,
          widescreenStretched,
        );
      }

      newControls.add(newControl);
      inactive.remove(obj.getId());
      if (newControl is ToggleControl && newControl.handlerId != null) {
        inactiveByHandler.remove(newControl.handlerId);
      }
    }

    for (final c in inactive.values) {
      c.resetState();
    }

    return newControls;
  }

  List<ControlDrawable> build(
    ControlScheme scheme,
    double baseW,
    double baseH,
    bool widescreenStretched,
  ) {
    return update(scheme, [], baseW, baseH, widescreenStretched);
  }

  Rect _rectFromObj(DisplayObject obj, double baseW, double baseH) {
    return Rect.fromLTWH(
      obj.getLeft() * baseW,
      obj.getTop() * baseH,
      obj.getWidth() * baseW,
      obj.getHeight() * baseH,
    );
  }

  Rect _hitRectFromObj(DisplayObject obj, double baseW, double baseH) {
    if (obj.hasHitRect) {
      return Rect.fromLTWH(
        (obj.hasHitLeft() ? obj.hitLeft : 0.0) * baseW,
        (obj.hasHitTop() ? obj.hitTop : 0.0) * baseH,
        (obj.hasHitWidth() ? obj.hitWidth : 0.0) * baseW,
        (obj.hasHitHeight() ? obj.hitHeight : 0.0) * baseH,
      );
    }
    return _rectFromObj(obj, baseW, baseH);
  }

  ui.Image? _bitmapFor(DisplayObject obj, String name) {
    final int id = obj.getAssetRef(name);
    if (id < 0) return null;
    final img = _bitmapCache[id];
    if (img == null) {
      _log.warning(
        'Cache miss for resource ID $id (Asset "$name" in Object ${obj.getId()})',
      );
    }
    return img;
  }

  DpadSkin _dpadSkinFromDisplayObject(DisplayObject obj) {
    if (!obj.hasAssets()) {
      return DpadSkin.builtInOrNull() ?? DpadSkin();
    }
    final skin = DpadSkin();
    for (int i = 0; i < DpadSkin.frameNames.length; i++) {
      skin.setFrame(i, _bitmapFor(obj, DpadSkin.frameNames[i]));
    }
    return skin;
  }

  ControlDrawable _updateImage(
    DisplayObject obj,
    ControlDrawable? existing,
    double baseW,
    double baseH,
    bool widescreenStretched,
  ) {
    final isFullScreen = (obj.hasWidth() ? obj.width : 1.0) > 0.95;

    if (widescreenStretched && isFullScreen) {
      SlicedBitmapControlDrawable drawable;
      if (existing is SlicedBitmapControlDrawable) {
        drawable = existing;
      } else {
        drawable = SlicedBitmapControlDrawable();
        drawable.setZOrder(obj.getId());
      }
      final bitmap = _bitmapFor(obj, 'up');
      drawable.setBitmap(bitmap);
      final rect = _rectFromObj(obj, baseW, baseH);
      drawable.setBounds(rect);
      drawable.setDisabled(obj.isHidden());
      drawable.setFilter(obj.getSamplingMode());
      drawable.debugName = 'SlicedImage(id=${obj.getId()})';
      return drawable;
    }

    BitmapControlDrawable drawable;
    if (existing is BitmapControlDrawable) {
      drawable = existing;
    } else {
      drawable = BitmapControlDrawable();
      drawable.setZOrder(obj.getId());
    }

    final bitmap = _bitmapFor(obj, 'up');
    drawable.setBitmap(bitmap);
    final rect = _rectFromObj(obj, baseW, baseH);
    drawable.setBounds(rect);
    drawable.setDisabled(obj.isHidden());
    drawable.setFilter(obj.getSamplingMode());
    drawable.debugName = 'Image(id=${obj.getId()}, type=${obj.getType()})';
    return drawable;
  }

  ControlDrawable _updateButton(
    DisplayObject obj,
    ControlDrawable? existing,
    double baseW,
    double baseH,
  ) {
    ToggleControl drawable;
    if (existing is ToggleControl) {
      drawable = existing;
      drawable.zOrder = obj.getId();
    } else {
      drawable = ToggleControl(
        obj.getId(),
        BitmapControlDrawable(),
        BitmapControlDrawable(),
      );
      drawable.controller = selectionController;
    }

    final upBmp = _bitmapFor(obj, 'up');
    final downBmp = _bitmapFor(obj, 'down');
    drawable.setUpBitmap(upBmp);
    drawable.setDownBitmap(downBmp);
    drawable.setId(obj.getFunctionHandler());
    final rect = _rectFromObj(obj, baseW, baseH);
    drawable.setBounds(rect);
    drawable.setHitRect(_hitRectFromObj(obj, baseW, baseH));
    drawable.setDisabled(obj.isHidden());
    drawable.setTint(obj.getSamplingMode());
    drawable.setDebugNames('Button(id=${obj.getId()}, type=${obj.getType()})');
    return drawable;
  }

  ControlDrawable _updateText(
    DisplayObject obj,
    ControlDrawable? existing,
    double baseW,
    double baseH,
  ) {
    TextControlDrawable drawable;
    if (existing is TextControlDrawable) {
      drawable = existing;
    } else {
      drawable = TextControlDrawable(obj.getId());
    }

    drawable.setBounds(_rectFromObj(obj, baseW, baseH));
    drawable.setDisabled(obj.isHidden());
    drawable.setText(obj.getText());
    drawable.setColor(obj.getColor());
    drawable.setTextSize((obj.getTextSize() ?? 0.03) * baseH);
    return drawable;
  }

  ControlDrawable _updateDpad(
    DisplayObject obj,
    ControlDrawable? existing,
    double baseW,
    double baseH,
  ) {
    DpadControl drawable;
    if (existing is DpadControl) {
      drawable = existing;
    } else if (preserveDpadDragEnabled && _dpadCache.containsKey(obj.getId())) {
      drawable = _dpadCache[obj.getId()]!;
    } else {
      drawable = DpadControl(obj.getId());
      drawable.onDpadUpdate = onDpadUpdate;
      drawable.setAllowDrag(floatDpadEnabled);
    }

    _dpadCache[obj.getId()] = drawable;

    drawable.setAspectRatio((baseH > 0) ? (baseW / baseH) : 1.0);
    drawable.setDeadzone(obj.getDeadzone());
    drawable.setBounds(
      _rectFromObj(obj, baseW, baseH),
      preserveDrag: preserveDpadDragEnabled,
    );
    drawable.setHitRect(_hitRectFromObj(obj, baseW, baseH));
    drawable.setDisabled(obj.isHidden());
    drawable.setSampling(obj.getSamplingMode());

    drawable.setSkin(_dpadSkinFromDisplayObject(obj));

    return drawable;
  }

  void recycle() {
    _log.fine('Clearing ${_bitmapCache.length} bitmaps.');
    for (final img in _bitmapCache.values) {
      img.dispose();
    }
    _bitmapCache.clear();
    _dpadCache.clear();
  }
}
