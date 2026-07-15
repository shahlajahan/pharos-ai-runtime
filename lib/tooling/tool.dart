import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';

abstract class Tool {
  String get id;

  Future<Result> execute(ToolContext context);
}
