import 'dart:io';

import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';

abstract class KnowledgeParser {
  Future<KnowledgeDefinition> parse(File file);
}
