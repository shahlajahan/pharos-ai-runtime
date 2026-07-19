import 'package:pharos_ai_runtime/company/organization/organization.dart';
import 'package:pharos_ai_runtime/company/repositories/organization_repository.dart';
import 'package:test/test.dart';

class _FakeOrganizationRepository implements OrganizationRepository {
  Organization? stored;

  @override
  Future<Organization?> load() async => stored;

  @override
  Future<void> save(Organization organization) async {
    stored = organization;
  }
}

void main() {
  test('OrganizationRepository contract compiles: exposes load() '
      'returning Organization? and save(Organization)', () async {
    final repository = _FakeOrganizationRepository();
    const organization = Organization(departments: []);

    expect(await repository.load(), isNull);

    await repository.save(organization);

    expect(await repository.load(), same(organization));
  });
}
