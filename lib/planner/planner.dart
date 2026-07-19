import 'package:pharos_ai_runtime/planner/plan.dart';

/// Decides whether a goal requires planning. A Planner never executes
/// anything itself — it only decides whether a goal is simple (handled
/// directly, no Plan needed) or complex (broken down into a Plan).
abstract class Planner {
  Plan? plan(String goal);
}
