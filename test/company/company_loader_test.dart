import 'dart:io';

import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:test/test.dart';

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('company_loader_test_');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  test('load() discovers documents from existing category folders', () async {
    final companyDir = Directory('${workspace.path}/company')..createSync();
    File(
      '${companyDir.path}/overview.md',
    ).writeAsStringSync('# Overview\n\nWe build software.');

    final productsDir = Directory('${workspace.path}/products')..createSync();
    File(
      '${productsDir.path}/petsupo.md',
    ).writeAsStringSync('# Petsupo\n\nA pet care marketplace.');

    const loader = CompanyLoader();
    final documents = await loader.load(workspace.path);

    expect(documents, hasLength(2));
    expect(
      documents.any((d) => d.category == 'company' && d.name == 'overview'),
      isTrue,
    );
    expect(
      documents.any((d) => d.category == 'products' && d.name == 'petsupo'),
      isTrue,
    );
  });

  test(
    'load() discovers multiple documents in one category, sorted by name',
    () async {
      final knowledgeDir = Directory('${workspace.path}/knowledge')
        ..createSync();
      File('${knowledgeDir.path}/b.md').writeAsStringSync('B content');
      File('${knowledgeDir.path}/a.md').writeAsStringSync('A content');

      const loader = CompanyLoader();
      final documents = await loader.load(workspace.path);

      expect(documents.map((d) => d.name), ['a', 'b']);
    },
  );

  test('load() ignores missing category folders without throwing', () async {
    // No subfolders created at all under the workspace.
    const loader = CompanyLoader();

    final documents = await loader.load(workspace.path);

    expect(documents, isEmpty);
  });

  test(
    'load() never fails when the workspace root itself does not exist',
    () async {
      const loader = CompanyLoader();

      final documents = await loader.load('${workspace.path}/does-not-exist');

      expect(documents, isEmpty);
    },
  );

  test('load() ignores hidden files', () async {
    final companyDir = Directory('${workspace.path}/company')..createSync();
    File('${companyDir.path}/.DS_Store').writeAsStringSync('junk');
    File(
      '${companyDir.path}/overview.md',
    ).writeAsStringSync('Overview content');

    const loader = CompanyLoader();
    final documents = await loader.load(workspace.path);

    expect(documents, hasLength(1));
    expect(documents.single.name, 'overview');
  });

  test(
    'load() discovers markdown files nested arbitrarily deep under a '
    'category, matching how real HQ workspaces are actually laid out '
    '(for example products/petsupo/overview.md, not products/overview.md)',
    () async {
      final productDir = Directory('${workspace.path}/products/petsupo')
        ..createSync(recursive: true);
      File(
        '${productDir.path}/overview.md',
      ).writeAsStringSync('# Petsupo\n\nA pet care marketplace.');

      final deeplyNestedDir = Directory(
        '${workspace.path}/knowledge/engineering/flutter',
      )..createSync(recursive: true);
      File(
        '${deeplyNestedDir.path}/architecture.md',
      ).writeAsStringSync('# Architecture\n\nClean architecture.');

      const loader = CompanyLoader();
      final documents = await loader.load(workspace.path);

      expect(documents, hasLength(2));
      expect(
        documents.any((d) => d.category == 'products' && d.name == 'overview'),
        isTrue,
      );
      expect(
        documents.any(
          (d) => d.category == 'knowledge' && d.name == 'architecture',
        ),
        isTrue,
      );
    },
  );

  test('load() ignores non-markdown files, even when nested', () async {
    final assetsDir = Directory('${workspace.path}/assets/brand')
      ..createSync(recursive: true);
    File('${assetsDir.path}/logo.png').writeAsStringSync('not markdown');
    File(
      '${assetsDir.path}/guidelines.md',
    ).writeAsStringSync('Brand guidelines.');

    const loader = CompanyLoader();
    final documents = await loader.load(workspace.path);

    expect(documents, hasLength(1));
    expect(documents.single.name, 'guidelines');
  });
}
