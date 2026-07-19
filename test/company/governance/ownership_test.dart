import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/ownership.dart';
import 'package:test/test.dart';

void main() {
  test('Ownership links a BusinessArea and a Department', () {
    const ownership = Ownership(
      businessArea: BudgetArea(),
      department: FinanceDepartment(),
    );

    expect(ownership.businessArea, const BudgetArea());
    expect(ownership.department, const FinanceDepartment());
  });
}
