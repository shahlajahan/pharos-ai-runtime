import 'package:pharos_ai_runtime/company/governance/ownership.dart';

/// A Company's governance model: which Department is responsible for
/// each BusinessArea. Just a list of Ownership records — no lookup
/// methods, no helpers, no mutation.
class CompanyGovernance {
  const CompanyGovernance({required this.ownerships});

  final List<Ownership> ownerships;
}
