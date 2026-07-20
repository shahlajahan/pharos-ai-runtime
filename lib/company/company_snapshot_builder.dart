import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/company_snapshot.dart';

/// Transforms a CompanyContext into a CompanySnapshot: normalizes
/// documents, removes duplicates, counts available assets, and detects
/// both empty and permanently-missing categories. Only deterministic
/// assembly and normalization — no LLM calls, no prompt generation, no
/// business decisions beyond identifying what is known and unknown.
class CompanySnapshotBuilder {
  const CompanySnapshotBuilder();

  /// HQ categories the Runtime has no connector for yet, so they are
  /// always reported as missing, regardless of what was loaded.
  static const List<String> _alwaysMissing = [
    'Revenue',
    'CRM',
    'Campaign Performance',
    'Search Console',
    'Finance',
    'Customer Metrics',
  ];

  CompanySnapshot build(CompanyContext context) {
    final company = _normalize(context.company);
    final knowledge = _normalize(context.knowledge);
    final products = _normalize(context.products);
    final assets = _normalize(context.assets);
    final websites = _normalize(context.websites);
    final analytics = _normalize(context.analytics);
    final social = _normalize(context.social);
    final services = _normalize(context.services);

    final categories = <String, List<String>>{
      'Company': company,
      'Knowledge': knowledge,
      'Products': products,
      'Assets': assets,
      'Websites': websites,
      'Analytics': analytics,
      'Social': social,
      'Services': services,
    };

    final knownData = [
      for (final entry in categories.entries)
        if (entry.value.isNotEmpty) entry.key,
    ];

    final missingData = [
      for (final entry in categories.entries)
        if (entry.value.isEmpty) entry.key,
      ..._alwaysMissing,
    ];

    final risks = [
      for (final category in missingData)
        '$category data is not connected — related decisions carry '
            'additional uncertainty.',
    ];

    final recommendationsInput = [...products, ...knowledge];

    return CompanySnapshot(
      company: company,
      products: products,
      capabilities: knowledge,
      assets: assets,
      websites: websites,
      analytics: analytics,
      social: social,
      services: services,
      knownData: knownData,
      missingData: missingData,
      risks: risks,
      recommendationsInput: recommendationsInput,
    );
  }

  /// Removes duplicate entries while preserving order. Real HQ documents
  /// can otherwise appear more than once (for example the same fact
  /// copied into two files).
  List<String> _normalize(List<String> entries) {
    final seen = <String>{};
    final result = <String>[];

    for (final entry in entries) {
      if (seen.add(entry)) {
        result.add(entry);
      }
    }

    return result;
  }
}
