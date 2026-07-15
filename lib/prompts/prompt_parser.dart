import 'dart:io';

import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';

abstract class PromptParser {
  Future<PromptDefinition> parse(File file);
}
