import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/company/company_document.dart';
import 'package:pharos_ai_runtime/core/logger.dart';

/// Loads CompanyDocuments from the HQ Workspace on disk. This is the
/// only place company facts are read from — the Runtime must never
/// assume company information is embedded inside prompts.
///
/// Missing folders (including a missing workspace root itself) are
/// ignored: the loader never fails just because one of the expected
/// categories does not exist.
///
/// Real HQ content is almost always nested below the category folder
/// itself (for example `products/petsupo/overview.md`, not
/// `products/overview.md`), so every markdown file under a category is
/// loaded regardless of depth.
class CompanyLoader {
  const CompanyLoader();

  static const Logger _logger = Logger();

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
    _logger.debug('CompanyLoader: HQ root = $workspaceRoot');

    final documents = <CompanyDocument>[];

    for (final category in categories) {
      final categoryDocuments = await _loadCategory(workspaceRoot, category);
      documents.addAll(categoryDocuments);

      _logger.debug(
        'CompanyLoader: category "$category" -> '
        '${categoryDocuments.length} markdown file(s) loaded',
      );
    }

    _logger.debug(
      'CompanyLoader: ${documents.length} CompanyDocument(s) created total',
    );

    return documents;
  }

  Future<List<CompanyDocument>> _loadCategory(
    String workspaceRoot,
    String category,
  ) async {
    final directory = Directory(p.join(workspaceRoot, category));

    if (!await directory.exists()) {
      _logger.debug(
        'CompanyLoader: category "$category" -> directory not found at '
        '${directory.path}, skipped',
      );

      return const [];
    }

    final files = <File>[];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is Directory) {
        _logger.debug('CompanyLoader: discovered directory ${entity.path}');
        continue;
      }

      if (entity is! File) {
        continue;
      }

      if (_isHidden(entity.path, root: directory.path)) {
        continue;
      }

      if (p.extension(entity.path) != '.md') {
        continue;
      }

      files.add(entity);
    }

    files.sort((a, b) => a.path.compareTo(b.path));

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

  /// True when [path] itself, or any path segment between [root] and the
  /// file, starts with a dot (for example `.git`, `.DS_Store`).
  bool _isHidden(String path, {required String root}) {
    final relative = p.relative(path, from: root);

    return p.split(relative).any((segment) => segment.startsWith('.'));
  }
}
