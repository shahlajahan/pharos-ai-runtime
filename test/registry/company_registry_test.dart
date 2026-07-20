import 'package:pharos_ai_runtime/registry/company_registry.dart';
import 'package:test/test.dart';

void main() {
  test('products exposes all five hardcoded products, in order', () {
    const registry = CompanyRegistry();

    expect(registry.products.map((p) => p.name), [
      'Petsupo',
      'DevAudit',
      'HubMonix',
      'devclean',
      'leadforge',
    ]);
  });

  test('enabledProducts() returns only enabled products, in order', () {
    const registry = CompanyRegistry();

    expect(registry.enabledProducts().map((p) => p.name), [
      'Petsupo',
      'DevAudit',
      'HubMonix',
      'devclean',
      'leadforge',
    ]);
  });

  test('every hardcoded product is currently enabled', () {
    const registry = CompanyRegistry();

    expect(registry.products.every((p) => p.enabled), isTrue);
  });
}
