import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';

/// Converts one company Decision into an executable Workflow. Contract
/// only — no implementation exists yet; execution is future roadmap
/// work. The Decision Engine determines what the company should do;
/// a WorkflowPlanner determines how it should be done.
abstract class WorkflowPlanner {
  Workflow plan(Decision decision, WorkflowContext context);
}
