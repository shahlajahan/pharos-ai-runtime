import 'dart:io';

import 'package:pharos_ai_runtime/company/company_context_builder.dart';
import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:test/test.dart';

/// Regression test for a real bug: CompanyLoader only looked directly
/// inside each category folder, but real HQ workspaces nest their
/// content one or more levels deeper (products/petsupo/overview.md,
/// knowledge/engineering/flutter/architecture.md, ...). Given a fake
/// workspace laid out the same way, the resulting CompanyContext must
/// not be empty.
void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync(
      'company_brain_grounding_test_',
    );

    Directory('${workspace.path}/company').createSync(recursive: true);
    File(
      '${workspace.path}/company/mission.md',
    ).writeAsStringSync('# Mission\n\nBuild useful software.');

    Directory('${workspace.path}/products/petsupo').createSync(recursive: true);
    File(
      '${workspace.path}/products/petsupo/overview.md',
    ).writeAsStringSync('# Petsupo\n\nA pet care marketplace.');

    Directory(
      '${workspace.path}/knowledge/engineering/flutter',
    ).createSync(recursive: true);
    File(
      '${workspace.path}/knowledge/engineering/flutter/architecture.md',
    ).writeAsStringSync('# Architecture\n\nClean architecture.');

    Directory('${workspace.path}/assets/services').createSync(recursive: true);
    File(
      '${workspace.path}/assets/services/firebase.md',
    ).writeAsStringSync('# Firebase\n\nUsed for analytics.');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  test('given an HQ workspace with nested markdown documents, the resulting '
      'CompanyContext is not empty', () async {
    const loader = CompanyLoader();
    const builder = CompanyContextBuilder();

    final documents = await loader.load(workspace.path);
    expect(documents, isNotEmpty);

    final context = builder.build(documents);

    expect(context.company, isNotEmpty);
    expect(context.products, isNotEmpty);
    expect(context.knowledge, isNotEmpty);
    expect(context.assets, isNotEmpty);

    expect(context.company.single, contains('Build useful software.'));
    expect(context.products.single, contains('A pet care marketplace.'));
    expect(context.knowledge.single, contains('Clean architecture.'));
    expect(context.assets.single, contains('Used for analytics.'));
  });
}
