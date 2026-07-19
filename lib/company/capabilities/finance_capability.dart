import 'package:pharos_ai_runtime/company/capabilities/capability.dart';

class FinanceCapability implements Capability {
  const FinanceCapability();

  @override
  String get id => 'finance';

  @override
  String get name => 'Finance';
}
