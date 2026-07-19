import 'package:pharos_ai_runtime/company/identity/company_locale.dart';
import 'package:pharos_ai_runtime/company/identity/company_location.dart';

/// A Company's global configuration. Currently just its locale and
/// location; later phases may extend it.
class CompanyConfiguration {
  const CompanyConfiguration({required this.locale, required this.location});

  final CompanyLocale locale;
  final CompanyLocation location;
}
