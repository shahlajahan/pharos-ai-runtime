import 'package:pharos_ai_runtime/company/capabilities/capability.dart';
import 'package:pharos_ai_runtime/company/departments/department.dart';

/// Links a Department to the Capabilities it provides.
class DepartmentCapabilities {
  const DepartmentCapabilities({
    required this.department,
    required this.capabilities,
  });

  final Department department;
  final List<Capability> capabilities;
}
