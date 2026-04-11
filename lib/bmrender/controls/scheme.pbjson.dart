// This is a generated file - do not edit.
//
// Generated from scheme.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use controlSchemeDescriptor instead')
const ControlScheme$json = {
  '1': 'ControlScheme',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'orientation', '3': 2, '4': 1, '5': 9, '10': 'orientation'},
    {'1': 'touch_enabled', '3': 3, '4': 1, '5': 8, '10': 'touchEnabled'},
    {
      '1': 'accelerometer_enabled',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'accelerometerEnabled'
    },
    {'1': 'width', '3': 5, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 5, '10': 'height'},
    {
      '1': 'resources',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.controls.AppResource',
      '10': 'resources'
    },
    {
      '1': 'display_objects',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.controls.DisplayObject',
      '10': 'displayObjects'
    },
    {
      '1': 'options',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.controls.ContextMenuOption',
      '10': 'options'
    },
  ],
};

/// Descriptor for `ControlScheme`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlSchemeDescriptor = $convert.base64Decode(
    'Cg1Db250cm9sU2NoZW1lEhgKB3ZlcnNpb24YASABKAlSB3ZlcnNpb24SIAoLb3JpZW50YXRpb2'
    '4YAiABKAlSC29yaWVudGF0aW9uEiMKDXRvdWNoX2VuYWJsZWQYAyABKAhSDHRvdWNoRW5hYmxl'
    'ZBIzChVhY2NlbGVyb21ldGVyX2VuYWJsZWQYBCABKAhSFGFjY2VsZXJvbWV0ZXJFbmFibGVkEh'
    'QKBXdpZHRoGAUgASgFUgV3aWR0aBIWCgZoZWlnaHQYBiABKAVSBmhlaWdodBIzCglyZXNvdXJj'
    'ZXMYByADKAsyFS5jb250cm9scy5BcHBSZXNvdXJjZVIJcmVzb3VyY2VzEkAKD2Rpc3BsYXlfb2'
    'JqZWN0cxgIIAMoCzIXLmNvbnRyb2xzLkRpc3BsYXlPYmplY3RSDmRpc3BsYXlPYmplY3RzEjUK'
    'B29wdGlvbnMYCSADKAsyGy5jb250cm9scy5Db250ZXh0TWVudU9wdGlvblIHb3B0aW9ucw==');

@$core.Deprecated('Use appResourceDescriptor instead')
const AppResource$json = {
  '1': 'AppResource',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'bitmap', '3': 2, '4': 1, '5': 12, '10': 'bitmap'},
  ],
};

/// Descriptor for `AppResource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appResourceDescriptor = $convert.base64Decode(
    'CgtBcHBSZXNvdXJjZRIOCgJpZBgBIAEoBVICaWQSFgoGYml0bWFwGAIgASgMUgZiaXRtYXA=');

@$core.Deprecated('Use displayObjectDescriptor instead')
const DisplayObject$json = {
  '1': 'DisplayObject',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'top', '3': 3, '4': 1, '5': 2, '10': 'top'},
    {'1': 'left', '3': 4, '4': 1, '5': 2, '10': 'left'},
    {'1': 'width', '3': 5, '4': 1, '5': 2, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 2, '10': 'height'},
    {'1': 'function_handler', '3': 7, '4': 1, '5': 9, '10': 'functionHandler'},
    {'1': 'hidden', '3': 8, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'has_hit_rect', '3': 9, '4': 1, '5': 8, '10': 'hasHitRect'},
    {'1': 'hit_top', '3': 10, '4': 1, '5': 2, '10': 'hitTop'},
    {'1': 'hit_left', '3': 11, '4': 1, '5': 2, '10': 'hitLeft'},
    {'1': 'hit_width', '3': 12, '4': 1, '5': 2, '10': 'hitWidth'},
    {'1': 'hit_height', '3': 13, '4': 1, '5': 2, '10': 'hitHeight'},
    {'1': 'text', '3': 14, '4': 1, '5': 9, '10': 'text'},
    {'1': 'text_size', '3': 15, '4': 1, '5': 2, '10': 'textSize'},
    {'1': 'color', '3': 16, '4': 1, '5': 5, '10': 'color'},
    {'1': 'sampling_mode', '3': 17, '4': 1, '5': 9, '10': 'samplingMode'},
    {'1': 'deadzone', '3': 18, '4': 1, '5': 2, '10': 'deadzone'},
    {'1': 'radial', '3': 19, '4': 1, '5': 8, '10': 'radial'},
    {
      '1': 'assets',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.controls.ControlAsset',
      '10': 'assets'
    },
  ],
};

/// Descriptor for `DisplayObject`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List displayObjectDescriptor = $convert.base64Decode(
    'Cg1EaXNwbGF5T2JqZWN0Eg4KAmlkGAEgASgFUgJpZBISCgR0eXBlGAIgASgJUgR0eXBlEhAKA3'
    'RvcBgDIAEoAlIDdG9wEhIKBGxlZnQYBCABKAJSBGxlZnQSFAoFd2lkdGgYBSABKAJSBXdpZHRo'
    'EhYKBmhlaWdodBgGIAEoAlIGaGVpZ2h0EikKEGZ1bmN0aW9uX2hhbmRsZXIYByABKAlSD2Z1bm'
    'N0aW9uSGFuZGxlchIWCgZoaWRkZW4YCCABKAhSBmhpZGRlbhIgCgxoYXNfaGl0X3JlY3QYCSAB'
    'KAhSCmhhc0hpdFJlY3QSFwoHaGl0X3RvcBgKIAEoAlIGaGl0VG9wEhkKCGhpdF9sZWZ0GAsgAS'
    'gCUgdoaXRMZWZ0EhsKCWhpdF93aWR0aBgMIAEoAlIIaGl0V2lkdGgSHQoKaGl0X2hlaWdodBgN'
    'IAEoAlIJaGl0SGVpZ2h0EhIKBHRleHQYDiABKAlSBHRleHQSGwoJdGV4dF9zaXplGA8gASgCUg'
    'h0ZXh0U2l6ZRIUCgVjb2xvchgQIAEoBVIFY29sb3ISIwoNc2FtcGxpbmdfbW9kZRgRIAEoCVIM'
    'c2FtcGxpbmdNb2RlEhoKCGRlYWR6b25lGBIgASgCUghkZWFkem9uZRIWCgZyYWRpYWwYEyABKA'
    'hSBnJhZGlhbBIuCgZhc3NldHMYFCADKAsyFi5jb250cm9scy5Db250cm9sQXNzZXRSBmFzc2V0'
    'cw==');

@$core.Deprecated('Use controlAssetDescriptor instead')
const ControlAsset$json = {
  '1': 'ControlAsset',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'resource_ref', '3': 2, '4': 1, '5': 5, '10': 'resourceRef'},
  ],
};

/// Descriptor for `ControlAsset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlAssetDescriptor = $convert.base64Decode(
    'CgxDb250cm9sQXNzZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxyZXNvdXJjZV9yZWYYAiABKA'
    'VSC3Jlc291cmNlUmVm');

@$core.Deprecated('Use contextMenuOptionDescriptor instead')
const ContextMenuOption$json = {
  '1': 'ContextMenuOption',
  '2': [
    {'1': 'icon_res_id', '3': 1, '4': 1, '5': 5, '10': 'iconResId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'event', '3': 3, '4': 1, '5': 9, '10': 'event'},
    {'1': 'close_on_select', '3': 4, '4': 1, '5': 8, '10': 'closeOnSelect'},
  ],
};

/// Descriptor for `ContextMenuOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextMenuOptionDescriptor = $convert.base64Decode(
    'ChFDb250ZXh0TWVudU9wdGlvbhIeCgtpY29uX3Jlc19pZBgBIAEoBVIJaWNvblJlc0lkEhQKBX'
    'RpdGxlGAIgASgJUgV0aXRsZRIUCgVldmVudBgDIAEoCVIFZXZlbnQSJgoPY2xvc2Vfb25fc2Vs'
    'ZWN0GAQgASgIUg1jbG9zZU9uU2VsZWN0');
