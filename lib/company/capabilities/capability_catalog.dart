import 'package:pharos_ai_runtime/company/capabilities/department_capabilities.dart';

/// The Company-wide catalog of which Capabilities each Department
/// provides. Just a list of DepartmentCapabilities — no graph, no
/// lookup, no helpers.
class CapabilityCatalog {
  const CapabilityCatalog({required this.departmentCapabilities});

  final List<DepartmentCapabilities> departmentCapabilities;
}
