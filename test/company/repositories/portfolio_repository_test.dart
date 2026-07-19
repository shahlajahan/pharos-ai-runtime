import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';
import 'package:pharos_ai_runtime/company/repositories/portfolio_repository.dart';
import 'package:test/test.dart';

class _FakePortfolioRepository implements PortfolioRepository {
  Portfolio? stored;

  @override
  Future<Portfolio?> load() async => stored;

  @override
  Future<void> save(Portfolio portfolio) async {
    stored = portfolio;
  }
}

void main() {
  test('PortfolioRepository contract compiles: exposes load() returning '
      'Portfolio? and save(Portfolio)', () async {
    final repository = _FakePortfolioRepository();
    const portfolio = Portfolio(products: [], projects: []);

    expect(await repository.load(), isNull);

    await repository.save(portfolio);

    expect(await repository.load(), same(portfolio));
  });
}
