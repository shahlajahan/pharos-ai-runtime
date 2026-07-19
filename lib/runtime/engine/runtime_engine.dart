import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';

/// Coordinates the Runtime pipeline.
/// Owns orchestration only.
abstract interface class RuntimeEngine {
  Future<WorkflowResult> execute(RuntimeIntent intent);
}
