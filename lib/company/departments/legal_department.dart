import 'package:pharos_ai_runtime/company/departments/department.dart';

class LegalDepartment implements Department {
  const LegalDepartment();

  @override
  String get id => 'legal';

  @override
  String get name => 'Legal';
}
