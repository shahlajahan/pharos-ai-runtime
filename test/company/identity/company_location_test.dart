import 'package:pharos_ai_runtime/company/identity/company_location.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyLocation can be instantiated', () {
    const location = CompanyLocation(
      country: 'USA',
      region: 'CA',
      city: 'San Francisco',
    );

    expect(location.country, 'USA');
    expect(location.region, 'CA');
    expect(location.city, 'San Francisco');
  });
}
