import 'package:pharos_ai_runtime/company/departments/department.dart';

class ProductDepartment implements Department {
  const ProductDepartment();

  @override
  String get id => 'product';

  @override
  String get name => 'Product';
}
