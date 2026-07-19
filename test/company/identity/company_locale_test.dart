import 'package:pharos_ai_runtime/company/identity/company_locale.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyLocale can be instantiated', () {
    const locale = CompanyLocale(
      languageCode: 'en',
      countryCode: 'US',
      timeZone: 'UTC',
      currencyCode: 'USD',
    );

    expect(locale.languageCode, 'en');
    expect(locale.countryCode, 'US');
    expect(locale.timeZone, 'UTC');
    expect(locale.currencyCode, 'USD');
  });
}
