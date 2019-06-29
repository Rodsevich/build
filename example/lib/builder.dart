// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'example.dart';

Builder copyBuilder(BuilderOptions options) => CopyBuilder();

Builder resolvingBuilder(BuilderOptions options) => ResolvingBuilder();

Builder cssBuilder(BuilderOptions options) => CssBuilder();

Builder aggregator(BuilderOptions options) {
  log.info('Creating AggregatorBuilder');
  return AggregatorBuilder();
}

Builder analyzer(BuilderOptions options) {
  log.info('Creating AnalyzerBuilder');
  return AnalyzerBuilder();
}

class AggregatorBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) {
    log.info('Creating lib/foo/bar/generated.dart');
    buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/foo/bar/generated.dart'),
        'export "package:example/builder.dart";\n'
        'export "package:example/example.dart";\n');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'lib/$lib$': ['lib/foo/bar/generated.dart']
      };
}

class AnalyzerBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.endsWith('lib/foo/bar/generated.dart')) {
      return;
    }
    log.fine('Analyzing for ${buildStep.inputId}');
    var library = await buildStep.inputLibrary;
    var resolver = buildStep.resolver;
    assert(await resolver.isLibrary(buildStep.inputId));
    var output =
        AssetId(buildStep.inputId.package, 'lib/foo/bar/generated.dart.info');
    var contents = 'Classes: ' +
        {
          ...library.topLevelElements,
          ...library.exportedLibraries
              .expand((expLib) => expLib.topLevelElements)
        }.whereType<ClassElement>().map((c) => c.name).join(', ');
    await buildStep.writeAsString(output, contents);
    // log.info('Escrito: ' + await buildStep.readAsString(output));
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.dart.info']
      };
}
