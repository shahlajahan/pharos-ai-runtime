import 'package:pharos_ai_runtime/prompts/daily_marketing_prompt.dart';
import 'package:pharos_ai_runtime/registry/company_product.dart';
import 'package:test/test.dart';

void main() {
  test('build() includes the product name, description, target audience, and '
      'value proposition', () {
    const prompt = DailyMarketingPrompt();
    const product = CompanyProduct(
      name: 'Petsupo',
      enabled: true,
      description: 'A pet care marketplace.',
      targetAudience: 'Pet owners.',
      valueProposition: 'Book pet care in minutes.',
    );

    final result = prompt.build(product);

    expect(result, contains('Petsupo'));
    expect(result, contains('A pet care marketplace.'));
    expect(result, contains('Pet owners.'));
    expect(result, contains('Book pet care in minutes.'));
  });

  test('build() returns a different prompt for a different product', () {
    const prompt = DailyMarketingPrompt();
    const productA = CompanyProduct(
      name: 'Petsupo',
      enabled: true,
      description: 'A pet care marketplace.',
      targetAudience: 'Pet owners.',
      valueProposition: 'Book pet care in minutes.',
    );
    const productB = CompanyProduct(
      name: 'DevAudit',
      enabled: true,
      description: 'A code auditing tool.',
      targetAudience: 'Engineering teams.',
      valueProposition: 'Catch issues before production.',
    );

    expect(prompt.build(productA), isNot(prompt.build(productB)));
  });
}
