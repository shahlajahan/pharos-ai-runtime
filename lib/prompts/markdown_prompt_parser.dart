import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_parser.dart';

class MarkdownPromptParser extends PromptParser {
  @override
  Future<PromptDefinition> parse(File file) async {
    final content = await file.readAsString();
    final id = p.basenameWithoutExtension(file.path);

    return PromptDefinition(id: id, content: content);
  }
}
