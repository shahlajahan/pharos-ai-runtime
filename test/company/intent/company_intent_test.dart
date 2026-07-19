import 'package:pharos_ai_runtime/company/intent/company_intent.dart';
import 'package:pharos_ai_runtime/company/intent/intent.dart';
import 'package:pharos_ai_runtime/company/intent/intent_status.dart';
import 'package:pharos_ai_runtime/company/intent/intent_type.dart';
import 'package:test/test.dart';

class _FakeIntent implements Intent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

void main() {
  test('CompanyIntent stores the three fields', () {
    final intent = _FakeIntent();
    final companyIntent = CompanyIntent(
      intent: intent,
      type: IntentType.strategic,
      status: IntentStatus.proposed,
    );

    expect(companyIntent.intent, same(intent));
    expect(companyIntent.type, IntentType.strategic);
    expect(companyIntent.status, IntentStatus.proposed);
  });
}
