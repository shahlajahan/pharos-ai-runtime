import 'package:pharos_ai_runtime/company/capabilities/capability_catalog.dart';
import 'package:pharos_ai_runtime/company/capabilities/department_capabilities.dart';
import 'package:pharos_ai_runtime/company/capabilities/engineering_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/marketing_capability.dart';
import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:pharos_ai_runtime/company/departments/marketing_department.dart';
import 'package:test/test.dart';

void main() {
  test('CapabilityCatalog contains DepartmentCapabilities', () {
    const catalog = CapabilityCatalog(
      departmentCapabilities: [
        DepartmentCapabilities(
          department: EngineeringDepartment(),
          capabilities: [EngineeringCapability()],
        ),
        DepartmentCapabilities(
          department: MarketingDepartment(),
          capabilities: [MarketingCapability()],
        ),
      ],
    );

    expect(catalog.departmentCapabilities, hasLength(2));
  });

  test('CapabilityCatalog can be empty', () {
    const catalog = CapabilityCatalog(departmentCapabilities: []);

    expect(catalog.departmentCapabilities, isEmpty);
  });
}
