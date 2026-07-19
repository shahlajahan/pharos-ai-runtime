import 'package:pharos_ai_runtime/company/intent/company_intent.dart';
import 'package:pharos_ai_runtime/company/intent/intent.dart';
import 'package:pharos_ai_runtime/company/intent/intent_catalog.dart';
import 'package:pharos_ai_runtime/company/intent/intent_status.dart';
import 'package:pharos_ai_runtime/company/intent/intent_type.dart';
import 'package:test/test.dart';

class _FakeIntent implements Intent {
  _FakeIntent(this.id, this.title);

  @override
  final String id;

  @override
  final String title;
}

void main() {
  test('IntentCatalog stores CompanyIntent objects', () {
    final catalog = IntentCatalog(
      intents: [
        CompanyIntent(
          intent: _FakeIntent('i1', 'Release version 2.0'),
          type: IntentType.strategic,
          status: IntentStatus.proposed,
        ),
        CompanyIntent(
          intent: _FakeIntent('i2', 'Reduce infrastructure cost'),
          type: IntentType.operational,
          status: IntentStatus.approved,
        ),
      ],
    );

    expect(catalog.intents, hasLength(2));
  });

  test('IntentCatalog can be empty', () {
    const catalog = IntentCatalog(intents: []);

    expect(catalog.intents, isEmpty);
  });
}
