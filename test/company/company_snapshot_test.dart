import 'package:pharos_ai_runtime/company/company_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('CompanySnapshot stores every section', () {
    const snapshot = CompanySnapshot(
      company: ['a'],
      products: ['b'],
      capabilities: ['c'],
      assets: ['d'],
      websites: ['e'],
      analytics: ['f'],
      social: ['g'],
      services: ['h'],
      knownData: ['Company'],
      missingData: ['CRM'],
      risks: ['CRM data is not connected.'],
      recommendationsInput: ['b', 'c'],
    );

    expect(snapshot.company, ['a']);
    expect(snapshot.products, ['b']);
    expect(snapshot.capabilities, ['c']);
    expect(snapshot.assets, ['d']);
    expect(snapshot.websites, ['e']);
    expect(snapshot.analytics, ['f']);
    expect(snapshot.social, ['g']);
    expect(snapshot.services, ['h']);
    expect(snapshot.knownData, ['Company']);
    expect(snapshot.missingData, ['CRM']);
    expect(snapshot.risks, ['CRM data is not connected.']);
    expect(snapshot.recommendationsInput, ['b', 'c']);
  });
}
