import 'package:pharos_ai_runtime/company/departments/department.dart';

class OperationsDepartment implements Department {
  const OperationsDepartment();

  @override
  String get id => 'operations';

  @override
  String get name => 'Operations';
}
