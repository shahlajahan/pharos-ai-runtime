import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/governance/business_area.dart';

/// Links a BusinessArea to the Department responsible for it. This
/// models responsibility, not authorization: it does not grant or
/// restrict who may act on the BusinessArea — permissions are a
/// separate, later concern.
class Ownership {
  const Ownership({required this.businessArea, required this.department});

  final BusinessArea businessArea;
  final Department department;
}
