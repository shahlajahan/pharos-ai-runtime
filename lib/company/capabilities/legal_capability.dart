import 'package:pharos_ai_runtime/company/capabilities/capability.dart';

class LegalCapability implements Capability {
  const LegalCapability();

  @override
  String get id => 'legal';

  @override
  String get name => 'Legal';
}
