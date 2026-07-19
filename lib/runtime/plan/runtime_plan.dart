import 'package:pharos_ai_runtime/runtime/plan/plan.dart';

/// Immutable, concrete Plan. No behavior.
class RuntimePlan implements Plan {
  const RuntimePlan({required this.id, required this.title});

  @override
  final String id;

  @override
  final String title;
}
