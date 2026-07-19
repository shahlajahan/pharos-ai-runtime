import 'package:pharos_ai_runtime/company/capabilities/capability.dart';
import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/governance/business_area.dart';
import 'package:pharos_ai_runtime/company/work/work_type.dart';

/// Answers "who performs which Capability on which BusinessArea, for
/// what WorkType?" — distinct from Ownership, which answers "who owns
/// the BusinessArea?". Pure semantic link — no helpers, no validation,
/// no methods.
class Responsibility {
  const Responsibility({
    required this.department,
    required this.capability,
    required this.businessArea,
    required this.workType,
  });

  final Department department;
  final Capability capability;
  final BusinessArea businessArea;
  final WorkType workType;
}
