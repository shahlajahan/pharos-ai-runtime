import 'package:pharos_ai_runtime/company/intent/company_intent.dart';

/// The Company-wide catalog of CompanyIntents. Nothing else.
class IntentCatalog {
  const IntentCatalog({required this.intents});

  final List<CompanyIntent> intents;
}
