import 'package:pharos_ai_runtime/company/departments/ceo_office.dart';
import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/departments/hr_department.dart';
import 'package:pharos_ai_runtime/company/departments/legal_department.dart';
import 'package:pharos_ai_runtime/company/departments/marketing_department.dart';
import 'package:pharos_ai_runtime/company/departments/operations_department.dart';
import 'package:pharos_ai_runtime/company/departments/product_department.dart';
import 'package:pharos_ai_runtime/company/departments/sales_department.dart';
import 'package:test/test.dart';

void main() {
  const departments = <Department>[
    CeoOffice(),
    FinanceDepartment(),
    MarketingDepartment(),
    EngineeringDepartment(),
    SalesDepartment(),
    ProductDepartment(),
    OperationsDepartment(),
    HrDepartment(),
    LegalDepartment(),
  ];

  test('every department implements Department', () {
    for (final department in departments) {
      expect(department, isA<Department>());
    }
  });

  test('every department exposes a non-empty id and name', () {
    for (final department in departments) {
      expect(department.id, isNotEmpty);
      expect(department.name, isNotEmpty);
    }
  });

  test('every department has a distinct id', () {
    final ids = departments.map((department) => department.id).toSet();

    expect(ids, hasLength(departments.length));
  });
}
