import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyContext stores every section', () {
    const context = CompanyContext(
      company: ['a'],
      knowledge: ['b'],
      products: ['c'],
      assets: ['d'],
      services: ['e'],
      websites: ['f'],
      social: ['g'],
      analytics: ['h'],
    );

    expect(context.company, ['a']);
    expect(context.knowledge, ['b']);
    expect(context.products, ['c']);
    expect(context.assets, ['d']);
    expect(context.services, ['e']);
    expect(context.websites, ['f']);
    expect(context.social, ['g']);
    expect(context.analytics, ['h']);
  });

  test('CompanyContext sections can be empty', () {
    const context = CompanyContext(
      company: [],
      knowledge: [],
      products: [],
      assets: [],
      services: [],
      websites: [],
      social: [],
      analytics: [],
    );

    expect(context.company, isEmpty);
    expect(context.products, isEmpty);
  });
}
