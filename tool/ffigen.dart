// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

// Regenerates lib/bmlib/bronze_monkey.g.dart from the header of the
// bronze-monkey checkout named in pubspec.yaml. Run after the header changes:
//
//   dart run tool/ffigen.dart

import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:yaml/yaml.dart';

const assetId = 'package:retouched/bmlib/bronze_monkey.g.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final pubspec = loadYaml(
    File.fromUri(packageRoot.resolve('pubspec.yaml')).readAsStringSync(),
  );
  final dir =
      pubspec['hooks']['user_defines']['retouched']['bronze_monkey_dir']
          as String;
  final header = packageRoot.resolve('$dir/').resolve('bronze_monkey.h');
  if (!File.fromUri(header).existsSync()) {
    stderr.writeln(
      'No header at ${header.toFilePath()}. Generate it in the bronze-monkey '
      'checkout with: cargo build --features cbindgen',
    );
    exit(1);
  }

  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/bmlib/bronze_monkey.g.dart'),
      style: const NativeExternalBindings(assetId: assetId),
      preamble: '// Generated from bronze_monkey.h by tool/ffigen.dart.',
    ),
    headers: Headers(
      entryPoints: [header],
      include: (uri) => uri == header,
      compilerOptions: _builtinIncludes(),
    ),
    functions: Functions.includeAll,
    structs: Structs.includeAll,
    enums: Enums(
      include: Declarations.includeAll,
      renameMember: (declaration, member) =>
          member.replaceFirst('${declaration.originalName}_', ''),
    ),
  ).generate();
}

List<String> _builtinIncludes() {
  try {
    final result = Process.runSync('clang', ['-print-resource-dir']);
    if (result.exitCode != 0) return const [];
    return ['-I${(result.stdout as String).trim()}/include'];
  } on ProcessException {
    return const [];
  }
}
