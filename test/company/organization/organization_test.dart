import 'package:pharos_ai_runtime/company/departments/ceo_office.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/organization/organization.dart';
import 'package:test/test.dart';

void main() {
  test('Organization owns Departments', () {
    const organization = Organization(
      departments: [CeoOffice(), FinanceDepartment()],
    );

    expect(organization.departments, hasLength(2));
  });

  test('Organization can have no Departments', () {
    const organization = Organization(departments: []);

    expect(organization.departments, isEmpty);
  });
}
