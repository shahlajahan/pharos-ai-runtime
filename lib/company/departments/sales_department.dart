import 'package:pharos_ai_runtime/company/departments/department.dart';

class SalesDepartment implements Department {
  const SalesDepartment();

  @override
  String get id => 'sales';

  @override
  String get name => 'Sales';
}
