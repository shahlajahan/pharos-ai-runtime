import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_parser.dart';

class KnowledgeRepository {
  KnowledgeRepository({required KnowledgeParser parser}) : _parser = parser;

  final KnowledgeParser _parser;

  Future<List<KnowledgeDefinition>> load(Directory knowledgeDirectory) async {
    final files = <File>[];

    await for (final entity in knowledgeDirectory.list()) {
      if (entity is! File) {
        continue;
      }

      final name = p.basename(entity.path);

      if (name.startsWith('.')) {
        continue;
      }

      if (p.extension(entity.path) != '.md') {
        continue;
      }

      files.add(entity);
    }

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    final definitions = <KnowledgeDefinition>[];

    for (final file in files) {
      definitions.add(await _parser.parse(file));
    }

    return definitions;
  }
}
