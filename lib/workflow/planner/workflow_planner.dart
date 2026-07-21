import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/planner/planning_result.dart';

/// Transforms one company Decision into a complete, validated execution
/// plan: selects the correct WorkflowDefinition, creates a
/// WorkflowInstance, resolves dependencies, validates workflow
/// consistency, and produces an ordered execution plan. Never executes
/// anything. Knows workflows, dependencies, and planning only — never
/// AI, agents, tools, HTTP, LLMs, APIs, finance, or CRM.
abstract class WorkflowPlanner {
  PlanningResult plan(Decision decision, WorkflowContext context);
}
