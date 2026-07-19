import 'package:pharos_ai_runtime/company/departments/department.dart';

class MarketingDepartment implements Department {
  const MarketingDepartment();

  @override
  String get id => 'marketing';

  @override
  String get name => 'Marketing';
}
