import 'package:pharos_ai_runtime/company/departments/department.dart';

class CeoOffice implements Department {
  const CeoOffice();

  @override
  String get id => 'ceo-office';

  @override
  String get name => 'CEO Office';
}
