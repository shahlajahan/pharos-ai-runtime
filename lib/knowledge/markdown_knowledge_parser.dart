import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_parser.dart';

class MarkdownKnowledgeParser extends KnowledgeParser {
  @override
  Future<KnowledgeDefinition> parse(File file) async {
    final content = await file.readAsString();
    final id = p.basenameWithoutExtension(file.path);

    final headingLine = content.split('\n').firstWhere(
      (line) => line.trim().startsWith('#'),
      orElse: () => '',
    );

    if (headingLine.isEmpty) {
      throw const FormatException('No markdown heading found in file.');
    }

    final title = headingLine.replaceFirst(RegExp(r'^#+\s*'), '').trim();

    return KnowledgeDefinition(id: id, title: title, content: content);
  }
}
