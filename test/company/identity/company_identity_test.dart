import 'package:pharos_ai_runtime/company/identity/company_identity.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyIdentity can be instantiated', () {
    const identity = CompanyIdentity(
      id: 'pharos',
      displayName: 'Pharos',
      legalName: 'Pharos Inc.',
    );

    expect(identity.id, 'pharos');
    expect(identity.displayName, 'Pharos');
    expect(identity.legalName, 'Pharos Inc.');
  });
}
