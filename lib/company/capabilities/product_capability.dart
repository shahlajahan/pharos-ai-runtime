import 'package:pharos_ai_runtime/company/capabilities/capability.dart';

class ProductCapability implements Capability {
  const ProductCapability();

  @override
  String get id => 'product';

  @override
  String get name => 'Product';
}
