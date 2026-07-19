import 'package:pharos_ai_runtime/company/departments/department.dart';

class EngineeringDepartment implements Department {
  const EngineeringDepartment();

  @override
  String get id => 'engineering';

  @override
  String get name => 'Engineering';
}
