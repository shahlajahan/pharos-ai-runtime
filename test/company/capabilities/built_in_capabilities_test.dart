import 'package:pharos_ai_runtime/company/capabilities/capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/engineering_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/finance_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/human_resources_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/legal_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/marketing_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/operations_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/product_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/sales_capability.dart';
import 'package:test/test.dart';

void main() {
  const capabilities = <Capability>[
    EngineeringCapability(),
    MarketingCapability(),
    FinanceCapability(),
    SalesCapability(),
    LegalCapability(),
    OperationsCapability(),
    HumanResourcesCapability(),
    ProductCapability(),
  ];

  test('every built-in capability instantiates correctly and implements '
      'Capability', () {
    for (final capability in capabilities) {
      expect(capability, isA<Capability>());
      expect(capability.id, isNotEmpty);
      expect(capability.name, isNotEmpty);
    }
  });

  test('every built-in capability has a distinct id', () {
    final ids = capabilities.map((capability) => capability.id).toSet();

    expect(ids, hasLength(capabilities.length));
  });
}
