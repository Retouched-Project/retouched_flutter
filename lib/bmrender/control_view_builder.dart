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

  bool hasAllResources(ControlScheme scheme) {
    for (final res in scheme.getResources()) {
      if (!_bitmapCache.containsKey(res.getId())) return false;
    }
    return true;
  }

  Future<Map<int, ui.Image>> decodeResources(ControlScheme scheme) async {
    final resources = scheme.getResources();
    _log.fine('Decoding resources: ${resources.length} resources.');

    final futures = <Future<MapEntry<int, ui.Image>?>>[];
    for (final res in resources) {
      final id = res.getId();
      final data = res.getBitmap();
      if (data != null && data.isNotEmpty) {
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
    }

    final results = await Future.wait(futures);
    final Map<int, ui.Image> staging = {};
    for (final entry in results) {
      if (entry != null) staging[entry.key] = entry.value;
    }
    return staging;
  }

  List<ui.Image> applyResources(Map<int, ui.Image> decoded) {
    final List<ui.Image> replaced = [];
    for (final entry in decoded.entries) {
      final old = _bitmapCache[entry.key];
      if (old != null) replaced.add(old);
      _bitmapCache[entry.key] = entry.value;
    }
    return replaced;
  }

  List<ControlDrawable> update(
    ControlScheme scheme,
    List<ControlDrawable> currentControls,
    double baseW,
    double baseH,
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
        newControl = _updateImage(obj, existing, baseW, baseH);
      } else if (obj.getType() == 'text') {
        newControl = _updateText(obj, existing, baseW, baseH);
      } else if (obj.getType() == 'dpad') {
        newControl = _updateDpad(obj, existing, baseW, baseH);
      } else if (obj.getFunctionHandler() != null &&
          obj.getFunctionHandler()!.isNotEmpty) {
        newControl = _updateButton(obj, existing, baseW, baseH);
      } else {
        newControl = _updateImage(obj, existing, baseW, baseH);
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
  ) {
    return update(scheme, [], baseW, baseH);
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

  ControlDrawable _updateImage(
    DisplayObject obj,
    ControlDrawable? existing,
    double baseW,
    double baseH,
  ) {
    final isFullScreen = (obj.hasWidth() ? obj.width : 1.0) > 0.95;

    if (isFullScreen) {
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

    drawable.setAspectRatio(1.0);
    drawable.setDeadzone(obj.getDeadzone());
    drawable.setBounds(
      _rectFromObj(obj, baseW, baseH),
      preserveDrag: preserveDpadDragEnabled,
    );
    drawable.setHitRect(_hitRectFromObj(obj, baseW, baseH));
    drawable.setDisabled(obj.isHidden());
    drawable.setSampling(obj.getSamplingMode());

    final skin = DpadSkin();
    for (int i = 0; i < DpadSkin.frameNames.length; i++) {
      skin.setFrame(i, _bitmapFor(obj, DpadSkin.frameNames[i]));
    }
    drawable.setSkin(skin);

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
