// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const assetName = 'bmlib/bronze_monkey.g.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final dir = input.userDefines.path('bronze_monkey_dir');
    if (dir == null) {
      throw const FormatException(
        'hooks.user_defines.retouched.bronze_monkey_dir must name a '
        'bronze-monkey checkout',
      );
    }
    final profile = input.userDefines['bronze_monkey_profile'] ?? 'release';

    final code = input.config.code;
    final triple = _rustTriple(code);
    final file = code.targetOS.dylibFileName('bronze_monkey');
    final library = dir.resolve('target/$triple/$profile/$file');

    if (!File.fromUri(library).existsSync()) {
      throw StateError(
        'No bronze-monkey library for ${code.targetOS} '
        '${code.targetArchitecture} at ${library.toFilePath()}. Build it in '
        '${dir.toFilePath()} with: ${_buildCommand(code, triple, profile)}',
      );
    }

    output.dependencies.add(library);
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: assetName,
        linkMode: DynamicLoadingBundled(),
        file: library,
      ),
    );
  });
}

String _rustTriple(CodeConfig code) {
  final os = code.targetOS;
  final arch = code.targetArchitecture;
  final triple = switch (os) {
    OS.android => switch (arch) {
      Architecture.arm64 => 'aarch64-linux-android',
      Architecture.arm => 'armv7-linux-androideabi',
      Architecture.x64 => 'x86_64-linux-android',
      Architecture.ia32 => 'i686-linux-android',
      _ => null,
    },
    OS.iOS => switch ((arch, code.iOS.targetSdk)) {
      (Architecture.arm64, IOSSdk.iPhoneOS) => 'aarch64-apple-ios',
      (Architecture.arm64, IOSSdk.iPhoneSimulator) => 'aarch64-apple-ios-sim',
      (Architecture.x64, IOSSdk.iPhoneSimulator) => 'x86_64-apple-ios',
      _ => null,
    },
    OS.linux => switch (arch) {
      Architecture.x64 => 'x86_64-unknown-linux-gnu',
      Architecture.arm64 => 'aarch64-unknown-linux-gnu',
      _ => null,
    },
    OS.macOS => switch (arch) {
      Architecture.arm64 => 'aarch64-apple-darwin',
      Architecture.x64 => 'x86_64-apple-darwin',
      _ => null,
    },
    OS.windows => switch (arch) {
      Architecture.x64 => 'x86_64-pc-windows-msvc',
      Architecture.arm64 => 'aarch64-pc-windows-msvc',
      _ => null,
    },
    _ => null,
  };
  if (triple == null) {
    throw UnsupportedError('bronze-monkey is not built for $os $arch');
  }
  return triple;
}

String _buildCommand(CodeConfig code, String triple, Object profile) {
  final release = profile == 'release' ? ' --release' : '';
  if (code.targetOS == OS.android) {
    return 'cargo ndk -t $triple build$release';
  }
  return 'cargo build$release --target $triple';
}
