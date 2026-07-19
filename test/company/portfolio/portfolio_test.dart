import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';
import 'package:pharos_ai_runtime/company/products/product.dart';
import 'package:pharos_ai_runtime/company/projects/project.dart';
import 'package:test/test.dart';

void main() {
  test('Portfolio exposes Products and Projects', () {
    const portfolio = Portfolio(
      products: [Product(id: 'p1', name: 'Pharos Runtime')],
      projects: [Project(id: 'j1', name: 'Company Domain Foundation')],
    );

    expect(portfolio.products, hasLength(1));
    expect(portfolio.projects, hasLength(1));
  });

  test('Portfolio can be empty', () {
    const portfolio = Portfolio(products: [], projects: []);

    expect(portfolio.products, isEmpty);
    expect(portfolio.projects, isEmpty);
  });
}
