import 'package:pharos_ai_runtime/company/departments/department.dart';

class FinanceDepartment implements Department {
  const FinanceDepartment();

  @override
  String get id => 'finance';

  @override
  String get name => 'Finance';
}
