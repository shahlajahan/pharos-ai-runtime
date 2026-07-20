import 'package:pharos_ai_runtime/company/company_document.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyDocument stores category, name, and content', () {
    const document = CompanyDocument(
      category: 'company',
      name: 'overview',
      content: '# Overview\n\nWe build software.',
    );

    expect(document.category, 'company');
    expect(document.name, 'overview');
    expect(document.content, '# Overview\n\nWe build software.');
  });
}
