import 'package:pharos_ai_runtime/registry/company_product.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyProduct stores name, enabled, and the prompt fields', () {
    const product = CompanyProduct(
      name: 'Petsupo',
      enabled: true,
      description: 'A pet care marketplace.',
      targetAudience: 'Pet owners.',
      valueProposition: 'Book pet care in minutes.',
    );

    expect(product.name, 'Petsupo');
    expect(product.enabled, isTrue);
    expect(product.description, 'A pet care marketplace.');
    expect(product.targetAudience, 'Pet owners.');
    expect(product.valueProposition, 'Book pet care in minutes.');
  });

  test('CompanyProduct can be disabled', () {
    const product = CompanyProduct(
      name: 'Petsupo',
      enabled: false,
      description: 'A pet care marketplace.',
      targetAudience: 'Pet owners.',
      valueProposition: 'Book pet care in minutes.',
    );

    expect(product.enabled, isFalse);
  });
}
