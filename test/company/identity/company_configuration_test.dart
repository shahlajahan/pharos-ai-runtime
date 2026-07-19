import 'package:pharos_ai_runtime/company/identity/company_configuration.dart';
import 'package:pharos_ai_runtime/company/identity/company_locale.dart';
import 'package:pharos_ai_runtime/company/identity/company_location.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyConfiguration groups Locale and Location', () {
    const locale = CompanyLocale(
      languageCode: 'en',
      countryCode: 'US',
      timeZone: 'UTC',
      currencyCode: 'USD',
    );
    const location = CompanyLocation(
      country: 'USA',
      region: 'CA',
      city: 'San Francisco',
    );
    const configuration = CompanyConfiguration(
      locale: locale,
      location: location,
    );

    expect(configuration.locale, same(locale));
    expect(configuration.location, same(location));
  });
}
