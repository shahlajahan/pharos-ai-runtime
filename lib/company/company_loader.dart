import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/company/company_document.dart';

/// Loads CompanyDocuments from the HQ Workspace on disk. This is the
/// only place company facts are read from — the Runtime must never
/// assume company information is embedded inside prompts.
///
/// Missing folders (including a missing workspace root itself) are
/// ignored: the loader never fails just because one of the expected
/// categories does not exist.
class CompanyLoader {
  const CompanyLoader();

  static const List<String> categories = [
    'company',
    'knowledge',
    'products',
    'assets',
    'services',
    'websites',
    'social',
    'analytics',
  ];

  Future<List<CompanyDocument>> load(String workspaceRoot) async {
    final documents = <CompanyDocument>[];

    for (final category in categories) {
      documents.addAll(await _loadCategory(workspaceRoot, category));
    }

    return documents;
  }

  Future<List<CompanyDocument>> _loadCategory(
    String workspaceRoot,
    String category,
  ) async {
    final directory = Directory(p.join(workspaceRoot, category));

    if (!await directory.exists()) {
      return const [];
    }

    final files = <File>[];

    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final name = p.basename(entity.path);

      if (name.startsWith('.')) {
        continue;
      }

      files.add(entity);
    }

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    final documents = <CompanyDocument>[];

    for (final file in files) {
      documents.add(
        CompanyDocument(
          category: category,
          name: p.basenameWithoutExtension(file.path),
          content: await file.readAsString(),
        ),
      );
    }

    return documents;
  }
}
