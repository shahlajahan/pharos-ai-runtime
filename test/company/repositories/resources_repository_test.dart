import 'package:pharos_ai_runtime/company/repositories/resources_repository.dart';
import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/resources.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';
import 'package:test/test.dart';

class _FakeResourcesRepository implements ResourcesRepository {
  Resources? stored;

  @override
  Future<Resources?> load() async => stored;

  @override
  Future<void> save(Resources resources) async {
    stored = resources;
  }
}

void main() {
  test('ResourcesRepository contract compiles: exposes load() returning '
      'Resources? and save(Resources)', () async {
    final repository = _FakeResourcesRepository();
    const resources = Resources(
      budget: Budget(),
      revenue: Revenue(),
      cashFlow: CashFlow(),
      expenses: Expenses(),
      aiCost: AiCost(),
      apiUsage: ApiUsage(),
    );

    expect(await repository.load(), isNull);

    await repository.save(resources);

    expect(await repository.load(), same(resources));
  });
}
