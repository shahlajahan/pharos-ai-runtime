import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/business_area.dart';
import 'package:pharos_ai_runtime/company/governance/configuration_area.dart';
import 'package:pharos_ai_runtime/company/governance/identity_area.dart';
import 'package:pharos_ai_runtime/company/governance/knowledge_area.dart';
import 'package:pharos_ai_runtime/company/governance/metrics_area.dart';
import 'package:pharos_ai_runtime/company/governance/portfolio_area.dart';
import 'package:test/test.dart';

class _FakeBusinessArea implements BusinessArea {
  @override
  String get id => 'fake';

  @override
  String get name => 'Fake Area';
}

void main() {
  test('BusinessArea exposes id and name', () {
    final area = _FakeBusinessArea();

    expect(area.id, 'fake');
    expect(area.name, 'Fake Area');
  });

  const areas = <BusinessArea>[
    BudgetArea(),
    PortfolioArea(),
    KnowledgeArea(),
    MetricsArea(),
    IdentityArea(),
    ConfigurationArea(),
  ];

  test('every typed business area can be instantiated and implements '
      'BusinessArea', () {
    for (final area in areas) {
      expect(area, isA<BusinessArea>());
      expect(area.id, isNotEmpty);
      expect(area.name, isNotEmpty);
    }
  });

  test('every typed business area has a distinct id', () {
    final ids = areas.map((area) => area.id).toSet();

    expect(ids, hasLength(areas.length));
  });
}
