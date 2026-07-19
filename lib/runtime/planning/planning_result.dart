import 'package:pharos_ai_runtime/runtime/plan/plan.dart';

/// The outcome of Planning: the Plan it produced.
class PlanningResult {
  const PlanningResult({required this.plan});

  final Plan plan;
}
