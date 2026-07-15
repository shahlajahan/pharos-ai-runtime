import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_parser.dart';

class PromptRepository {
  PromptRepository({required PromptParser parser}) : _parser = parser;

  final PromptParser _parser;

  Future<List<PromptDefinition>> load(Directory promptsDirectory) async {
    final files = <File>[];

    await for (final entity in promptsDirectory.list()) {
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

    final definitions = <PromptDefinition>[];

    for (final file in files) {
      definitions.add(await _parser.parse(file));
    }

    return definitions;
  }
}
