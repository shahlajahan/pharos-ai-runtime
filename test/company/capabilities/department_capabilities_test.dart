import 'package:pharos_ai_runtime/company/capabilities/department_capabilities.dart';
import 'package:pharos_ai_runtime/company/capabilities/engineering_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/product_capability.dart';
import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:test/test.dart';

void main() {
  test('DepartmentCapabilities links a Department and its Capabilities', () {
    const departmentCapabilities = DepartmentCapabilities(
      department: EngineeringDepartment(),
      capabilities: [EngineeringCapability(), ProductCapability()],
    );

    expect(departmentCapabilities.department, const EngineeringDepartment());
    expect(departmentCapabilities.capabilities, hasLength(2));
  });

  test('DepartmentCapabilities can have no Capabilities', () {
    const departmentCapabilities = DepartmentCapabilities(
      department: EngineeringDepartment(),
      capabilities: [],
    );

    expect(departmentCapabilities.capabilities, isEmpty);
  });
}
