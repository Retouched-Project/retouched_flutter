// This is a generated file - do not edit.
//
// Generated from scheme.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ControlScheme extends $pb.GeneratedMessage {
  factory ControlScheme({
    $core.String? version,
    $core.String? orientation,
    $core.bool? touchEnabled,
    $core.bool? accelerometerEnabled,
    $core.int? width,
    $core.int? height,
    $core.Iterable<AppResource>? resources,
    $core.Iterable<DisplayObject>? displayObjects,
    $core.Iterable<ContextMenuOption>? options,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (orientation != null) result.orientation = orientation;
    if (touchEnabled != null) result.touchEnabled = touchEnabled;
    if (accelerometerEnabled != null)
      result.accelerometerEnabled = accelerometerEnabled;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (resources != null) result.resources.addAll(resources);
    if (displayObjects != null) result.displayObjects.addAll(displayObjects);
    if (options != null) result.options.addAll(options);
    return result;
  }

  ControlScheme._();

  factory ControlScheme.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControlScheme.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlScheme',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'controls'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aOS(2, _omitFieldNames ? '' : 'orientation')
    ..aOB(3, _omitFieldNames ? '' : 'touchEnabled')
    ..aOB(4, _omitFieldNames ? '' : 'accelerometerEnabled')
    ..aI(5, _omitFieldNames ? '' : 'width')
    ..aI(6, _omitFieldNames ? '' : 'height')
    ..pPM<AppResource>(7, _omitFieldNames ? '' : 'resources',
        subBuilder: AppResource.create)
    ..pPM<DisplayObject>(8, _omitFieldNames ? '' : 'displayObjects',
        subBuilder: DisplayObject.create)
    ..pPM<ContextMenuOption>(9, _omitFieldNames ? '' : 'options',
        subBuilder: ContextMenuOption.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlScheme clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlScheme copyWith(void Function(ControlScheme) updates) =>
      super.copyWith((message) => updates(message as ControlScheme))
          as ControlScheme;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControlScheme create() => ControlScheme._();
  @$core.override
  ControlScheme createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ControlScheme getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControlScheme>(create);
  static ControlScheme? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get orientation => $_getSZ(1);
  @$pb.TagNumber(2)
  set orientation($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrientation() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrientation() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get touchEnabled => $_getBF(2);
  @$pb.TagNumber(3)
  set touchEnabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTouchEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearTouchEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get accelerometerEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set accelerometerEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccelerometerEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccelerometerEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get width => $_getIZ(4);
  @$pb.TagNumber(5)
  set width($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(4);
  @$pb.TagNumber(5)
  void clearWidth() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get height => $_getIZ(5);
  @$pb.TagNumber(6)
  set height($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeight() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<AppResource> get resources => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<DisplayObject> get displayObjects => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<ContextMenuOption> get options => $_getList(8);
}

class AppResource extends $pb.GeneratedMessage {
  factory AppResource({
    $core.int? id,
    $core.List<$core.int>? bitmap,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (bitmap != null) result.bitmap = bitmap;
    return result;
  }

  AppResource._();

  factory AppResource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AppResource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppResource',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'controls'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'bitmap', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppResource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppResource copyWith(void Function(AppResource) updates) =>
      super.copyWith((message) => updates(message as AppResource))
          as AppResource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AppResource create() => AppResource._();
  @$core.override
  AppResource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AppResource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppResource>(create);
  static AppResource? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get bitmap => $_getN(1);
  @$pb.TagNumber(2)
  set bitmap($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBitmap() => $_has(1);
  @$pb.TagNumber(2)
  void clearBitmap() => $_clearField(2);
}

class DisplayObject extends $pb.GeneratedMessage {
  factory DisplayObject({
    $core.int? id,
    $core.String? type,
    $core.double? top,
    $core.double? left,
    $core.double? width,
    $core.double? height,
    $core.String? functionHandler,
    $core.bool? hidden,
    $core.bool? hasHitRect,
    $core.double? hitTop,
    $core.double? hitLeft,
    $core.double? hitWidth,
    $core.double? hitHeight,
    $core.String? text,
    $core.double? textSize,
    $core.int? color,
    $core.String? samplingMode,
    $core.double? deadzone,
    $core.bool? radial,
    $core.Iterable<ControlAsset>? assets,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (top != null) result.top = top;
    if (left != null) result.left = left;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (functionHandler != null) result.functionHandler = functionHandler;
    if (hidden != null) result.hidden = hidden;
    if (hasHitRect != null) result.hasHitRect = hasHitRect;
    if (hitTop != null) result.hitTop = hitTop;
    if (hitLeft != null) result.hitLeft = hitLeft;
    if (hitWidth != null) result.hitWidth = hitWidth;
    if (hitHeight != null) result.hitHeight = hitHeight;
    if (text != null) result.text = text;
    if (textSize != null) result.textSize = textSize;
    if (color != null) result.color = color;
    if (samplingMode != null) result.samplingMode = samplingMode;
    if (deadzone != null) result.deadzone = deadzone;
    if (radial != null) result.radial = radial;
    if (assets != null) result.assets.addAll(assets);
    return result;
  }

  DisplayObject._();

  factory DisplayObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DisplayObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'controls'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aD(3, _omitFieldNames ? '' : 'top', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'left', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OF)
    ..aOS(7, _omitFieldNames ? '' : 'functionHandler')
    ..aOB(8, _omitFieldNames ? '' : 'hidden')
    ..aOB(9, _omitFieldNames ? '' : 'hasHitRect')
    ..aD(10, _omitFieldNames ? '' : 'hitTop', fieldType: $pb.PbFieldType.OF)
    ..aD(11, _omitFieldNames ? '' : 'hitLeft', fieldType: $pb.PbFieldType.OF)
    ..aD(12, _omitFieldNames ? '' : 'hitWidth', fieldType: $pb.PbFieldType.OF)
    ..aD(13, _omitFieldNames ? '' : 'hitHeight', fieldType: $pb.PbFieldType.OF)
    ..aOS(14, _omitFieldNames ? '' : 'text')
    ..aD(15, _omitFieldNames ? '' : 'textSize', fieldType: $pb.PbFieldType.OF)
    ..aI(16, _omitFieldNames ? '' : 'color')
    ..aOS(17, _omitFieldNames ? '' : 'samplingMode')
    ..aD(18, _omitFieldNames ? '' : 'deadzone', fieldType: $pb.PbFieldType.OF)
    ..aOB(19, _omitFieldNames ? '' : 'radial')
    ..pPM<ControlAsset>(20, _omitFieldNames ? '' : 'assets',
        subBuilder: ControlAsset.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayObject copyWith(void Function(DisplayObject) updates) =>
      super.copyWith((message) => updates(message as DisplayObject))
          as DisplayObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisplayObject create() => DisplayObject._();
  @$core.override
  DisplayObject createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DisplayObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisplayObject>(create);
  static DisplayObject? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get top => $_getN(2);
  @$pb.TagNumber(3)
  set top($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTop() => $_has(2);
  @$pb.TagNumber(3)
  void clearTop() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get left => $_getN(3);
  @$pb.TagNumber(4)
  set left($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLeft() => $_has(3);
  @$pb.TagNumber(4)
  void clearLeft() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get width => $_getN(4);
  @$pb.TagNumber(5)
  set width($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(4);
  @$pb.TagNumber(5)
  void clearWidth() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get height => $_getN(5);
  @$pb.TagNumber(6)
  set height($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeight() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get functionHandler => $_getSZ(6);
  @$pb.TagNumber(7)
  set functionHandler($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFunctionHandler() => $_has(6);
  @$pb.TagNumber(7)
  void clearFunctionHandler() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hidden => $_getBF(7);
  @$pb.TagNumber(8)
  set hidden($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHidden() => $_has(7);
  @$pb.TagNumber(8)
  void clearHidden() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get hasHitRect => $_getBF(8);
  @$pb.TagNumber(9)
  set hasHitRect($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHasHitRect() => $_has(8);
  @$pb.TagNumber(9)
  void clearHasHitRect() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get hitTop => $_getN(9);
  @$pb.TagNumber(10)
  set hitTop($core.double value) => $_setFloat(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHitTop() => $_has(9);
  @$pb.TagNumber(10)
  void clearHitTop() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get hitLeft => $_getN(10);
  @$pb.TagNumber(11)
  set hitLeft($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHitLeft() => $_has(10);
  @$pb.TagNumber(11)
  void clearHitLeft() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get hitWidth => $_getN(11);
  @$pb.TagNumber(12)
  set hitWidth($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasHitWidth() => $_has(11);
  @$pb.TagNumber(12)
  void clearHitWidth() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get hitHeight => $_getN(12);
  @$pb.TagNumber(13)
  set hitHeight($core.double value) => $_setFloat(12, value);
  @$pb.TagNumber(13)
  $core.bool hasHitHeight() => $_has(12);
  @$pb.TagNumber(13)
  void clearHitHeight() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get text => $_getSZ(13);
  @$pb.TagNumber(14)
  set text($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasText() => $_has(13);
  @$pb.TagNumber(14)
  void clearText() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get textSize => $_getN(14);
  @$pb.TagNumber(15)
  set textSize($core.double value) => $_setFloat(14, value);
  @$pb.TagNumber(15)
  $core.bool hasTextSize() => $_has(14);
  @$pb.TagNumber(15)
  void clearTextSize() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get color => $_getIZ(15);
  @$pb.TagNumber(16)
  set color($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasColor() => $_has(15);
  @$pb.TagNumber(16)
  void clearColor() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get samplingMode => $_getSZ(16);
  @$pb.TagNumber(17)
  set samplingMode($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasSamplingMode() => $_has(16);
  @$pb.TagNumber(17)
  void clearSamplingMode() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get deadzone => $_getN(17);
  @$pb.TagNumber(18)
  set deadzone($core.double value) => $_setFloat(17, value);
  @$pb.TagNumber(18)
  $core.bool hasDeadzone() => $_has(17);
  @$pb.TagNumber(18)
  void clearDeadzone() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get radial => $_getBF(18);
  @$pb.TagNumber(19)
  set radial($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasRadial() => $_has(18);
  @$pb.TagNumber(19)
  void clearRadial() => $_clearField(19);

  @$pb.TagNumber(20)
  $pb.PbList<ControlAsset> get assets => $_getList(19);
}

class ControlAsset extends $pb.GeneratedMessage {
  factory ControlAsset({
    $core.String? name,
    $core.int? resourceRef,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (resourceRef != null) result.resourceRef = resourceRef;
    return result;
  }

  ControlAsset._();

  factory ControlAsset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ControlAsset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlAsset',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'controls'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'resourceRef')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlAsset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlAsset copyWith(void Function(ControlAsset) updates) =>
      super.copyWith((message) => updates(message as ControlAsset))
          as ControlAsset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ControlAsset create() => ControlAsset._();
  @$core.override
  ControlAsset createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ControlAsset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControlAsset>(create);
  static ControlAsset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get resourceRef => $_getIZ(1);
  @$pb.TagNumber(2)
  set resourceRef($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResourceRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearResourceRef() => $_clearField(2);
}

class ContextMenuOption extends $pb.GeneratedMessage {
  factory ContextMenuOption({
    $core.int? iconResId,
    $core.String? title,
    $core.String? event,
    $core.bool? closeOnSelect,
  }) {
    final result = create();
    if (iconResId != null) result.iconResId = iconResId;
    if (title != null) result.title = title;
    if (event != null) result.event = event;
    if (closeOnSelect != null) result.closeOnSelect = closeOnSelect;
    return result;
  }

  ContextMenuOption._();

  factory ContextMenuOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextMenuOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextMenuOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'controls'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'iconResId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'event')
    ..aOB(4, _omitFieldNames ? '' : 'closeOnSelect')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextMenuOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextMenuOption copyWith(void Function(ContextMenuOption) updates) =>
      super.copyWith((message) => updates(message as ContextMenuOption))
          as ContextMenuOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextMenuOption create() => ContextMenuOption._();
  @$core.override
  ContextMenuOption createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextMenuOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextMenuOption>(create);
  static ContextMenuOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get iconResId => $_getIZ(0);
  @$pb.TagNumber(1)
  set iconResId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIconResId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIconResId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get event => $_getSZ(2);
  @$pb.TagNumber(3)
  set event($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEvent() => $_has(2);
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get closeOnSelect => $_getBF(3);
  @$pb.TagNumber(4)
  set closeOnSelect($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCloseOnSelect() => $_has(3);
  @$pb.TagNumber(4)
  void clearCloseOnSelect() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
