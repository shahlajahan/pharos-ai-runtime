import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';

/// Pure data: carries the RuntimeIntent a Planner should transform into
/// an executable plan.
class PlanningRequest {
  const PlanningRequest({required this.intent});

  final RuntimeIntent intent;
}
