import 'package:pharos_ai_runtime/company/governance/company_governance.dart';
import 'package:pharos_ai_runtime/company/repositories/governance_repository.dart';
import 'package:test/test.dart';

class _FakeGovernanceRepository implements GovernanceRepository {
  CompanyGovernance? stored;

  @override
  Future<CompanyGovernance?> load() async => stored;

  @override
  Future<void> save(CompanyGovernance governance) async {
    stored = governance;
  }
}

void main() {
  test('GovernanceRepository contract compiles: exposes load() returning '
      'CompanyGovernance? and save(CompanyGovernance)', () async {
    final repository = _FakeGovernanceRepository();
    const governance = CompanyGovernance(ownerships: []);

    expect(await repository.load(), isNull);

    await repository.save(governance);

    expect(await repository.load(), same(governance));
  });
}
