/// A Company's locale settings. Stores only values — no conversion, no
/// formatting.
///
/// Examples: languageCode "en"/"tr"/"fa", countryCode "TR"/"US",
/// currencyCode "TRY"/"USD"/"EUR".
class CompanyLocale {
  const CompanyLocale({
    required this.languageCode,
    required this.countryCode,
    required this.timeZone,
    required this.currencyCode,
  });

  final String languageCode;
  final String countryCode;
  final String timeZone;
  final String currencyCode;
}
