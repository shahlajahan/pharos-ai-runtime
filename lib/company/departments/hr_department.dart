import 'package:pharos_ai_runtime/company/departments/department.dart';

class HrDepartment implements Department {
  const HrDepartment();

  @override
  String get id => 'hr';

  @override
  String get name => 'HR';
}
