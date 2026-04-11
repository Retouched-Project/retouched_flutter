import 'dart:ui';
import 'scheme.pb.dart';
import 'control_orientation.dart';
import 'sampling_mode.dart';
import 'dart:typed_data';

extension ControlSchemeExt on ControlScheme {
  ControlOrientation getRotation() {
    return ControlOrientation.fromString(orientation);
  }

  bool isTouchEnabled() => hasTouchEnabled() ? touchEnabled : false;
  bool isAccelerometerEnabled() =>
      hasAccelerometerEnabled() ? accelerometerEnabled : false;

  int getWidth() => hasWidth() ? width : 0;
  int getHeight() => hasHeight() ? height : 0;

  List<AppResource> getResources() => resources;
  List<DisplayObject> getDisplayObjects() => displayObjects;
  List<ContextMenuOption> getOptions() => options;

  ControlScheme merge(ControlScheme other) {
    final newScheme = clone();
    if (other.hasVersion()) newScheme.version = other.version;
    if (other.hasOrientation()) newScheme.orientation = other.orientation;
    if (other.hasTouchEnabled()) newScheme.touchEnabled = other.touchEnabled;
    if (other.hasAccelerometerEnabled()) {
      newScheme.accelerometerEnabled = other.accelerometerEnabled;
    }
    if (other.hasWidth()) newScheme.width = other.width;
    if (other.hasHeight()) newScheme.height = other.height;

    if (other.resources.isNotEmpty) {
      newScheme.resources.clear();
      newScheme.resources.addAll(other.resources);
    }

    if (other.displayObjects.isNotEmpty) {
      newScheme.displayObjects.clear();
      newScheme.displayObjects.addAll(other.displayObjects);
    }

    if (other.options.isNotEmpty) {
      newScheme.options.clear();
      newScheme.options.addAll(other.options);
    }

    return newScheme;
  }
}

extension AppResourceExt on AppResource {
  int getId() => hasId() ? id : 0;
  Uint8List? getBitmap() => hasBitmap() ? Uint8List.fromList(bitmap) : null;
}

extension DisplayObjectExt on DisplayObject {
  int getId() => hasId() ? id : 0;
  String getType() => hasType() ? type : '';

  double getTop() => hasTop() ? top : 0.0;
  double getLeft() => hasLeft() ? left : 0.0;
  double getWidth() => hasWidth() ? width : 0.0;
  double getHeight() => hasHeight() ? height : 0.0;

  String? getFunctionHandler() => hasFunctionHandler() ? functionHandler : null;
  bool isHidden() => hasHidden() ? hidden : false;

  String? getText() => hasText() ? text : null;
  double? getTextSize() => hasTextSize() ? textSize : null;
  int? getColor() => hasColor() ? color : null;

  double getDeadzone() => hasDeadzone() ? deadzone : 0.25;

  SamplingMode getSamplingMode() {
    if (!hasSamplingMode()) return SamplingMode.bilinear;
    switch (samplingMode) {
      case 'nearest':
        return SamplingMode.nearestNeighbor;
      case 'linear':
        return SamplingMode.bilinear;
      default:
        return SamplingMode.bilinear;
    }
  }

  Rect getRect() {
    return Rect.fromLTWH(getLeft(), getTop(), getWidth(), getHeight());
  }

  Rect getHitRect() {
    if (hasHitRect) {
      return Rect.fromLTWH(
        hasHitLeft() ? hitLeft : 0.0,
        hasHitTop() ? hitTop : 0.0,
        hasHitWidth() ? hitWidth : 0.0,
        hasHitHeight() ? hitHeight : 0.0,
      );
    }
    return getRect();
  }

  bool hasAssets() => assets.isNotEmpty;

  int getAssetRef(String name) {
    for (final asset in assets) {
      if (asset.hasName() && asset.name == name) {
        return asset.hasResourceRef() ? asset.resourceRef : -1;
      }
    }
    return -1;
  }
}

extension ControlAssetExt on ControlAsset {
  String getName() => hasName() ? name : '';
  int getResourceRef() => hasResourceRef() ? resourceRef : -1;
}

extension ContextMenuOptionExt on ContextMenuOption {
  int getIconResId() => hasIconResId() ? iconResId : 0;
  String getTitle() => hasTitle() ? title : '';
  String getEvent() => hasEvent() ? event : '';
  bool isCloseOnSelect() => hasCloseOnSelect() ? closeOnSelect : false;
}
