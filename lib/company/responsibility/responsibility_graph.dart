import 'package:pharos_ai_runtime/company/responsibility/responsibility.dart';

/// The Company's semantic backbone: which Department is responsible for
/// which Capability on which BusinessArea, for which WorkType. Just a
/// list of Responsibilities — no graph traversal, no lookup, no
/// mutation.
class ResponsibilityGraph {
  const ResponsibilityGraph({required this.responsibilities});

  final List<Responsibility> responsibilities;
}
