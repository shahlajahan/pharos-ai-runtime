import 'package:pharos_ai_runtime/company/capabilities/engineering_capability.dart';
import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:pharos_ai_runtime/company/governance/portfolio_area.dart';
import 'package:pharos_ai_runtime/company/responsibility/responsibility.dart';
import 'package:pharos_ai_runtime/company/work/work_type.dart';
import 'package:test/test.dart';

void main() {
  test('Responsibility can be instantiated', () {
    const responsibility = Responsibility(
      department: EngineeringDepartment(),
      capability: EngineeringCapability(),
      businessArea: PortfolioArea(),
      workType: WorkType.engineering,
    );

    expect(responsibility, isNotNull);
  });

  test('Responsibility links exactly Department, Capability, BusinessArea, '
      'and WorkType', () {
    const responsibility = Responsibility(
      department: EngineeringDepartment(),
      capability: EngineeringCapability(),
      businessArea: PortfolioArea(),
      workType: WorkType.engineering,
    );

    expect(responsibility.department, const EngineeringDepartment());
    expect(responsibility.capability, const EngineeringCapability());
    expect(responsibility.businessArea, const PortfolioArea());
    expect(responsibility.workType, WorkType.engineering);
  });
}
