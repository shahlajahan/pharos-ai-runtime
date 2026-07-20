import 'package:pharos_ai_runtime/registry/company_product.dart';

/// Builds the prompt used to generate one product's section of the daily
/// marketing report.
class DailyMarketingPrompt {
  const DailyMarketingPrompt();

  String build(CompanyProduct product) {
    return 'Write a short daily marketing update for the following '
        'product.\n\n'
        'Product name: ${product.name}\n'
        'Description: ${product.description}\n'
        'Target audience: ${product.targetAudience}\n'
        'Value proposition: ${product.valueProposition}';
  }
}
