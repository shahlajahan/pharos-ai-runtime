import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// A single, deterministic, immutable unit of company knowledge — the
/// Runtime's language. FactExtractor produces these once from HQ
/// documents; nothing downstream ever mutates or re-derives them.
/// Markdown never travels past extraction: a CompanyFact carries only
/// its identity and structured attributes, never raw document prose.
class CompanyFact {
  const CompanyFact({
    required this.id,
    required this.type,
    required this.name,
    required this.attributes,
    required this.sources,
    required this.extractionRule,
    required this.confidence,
    required this.visibleTo,
  });

  /// Stable, deterministic identity, for example "product:petsupo".
  final String id;

  final FactType type;
  final String name;

  /// Structured, type-specific detail. Empty whenever FactExtractor
  /// cannot populate a field deterministically — an empty map is never
  /// backfilled with inferred or invented content.
  final Map<String, Object> attributes;

  /// The HQ documents this fact was extracted from (for example
  /// "products/petsupo"), for traceability.
  final List<String> sources;

  /// Which deterministic rule inside FactExtractor produced this fact
  /// (for example "product-from-category"), for traceability.
  final String extractionRule;

  /// Always 1.0 today: FactExtractor only emits facts it is certain
  /// about. Reserved for future, less-certain extraction rules.
  final double confidence;

  /// Which departments this fact is relevant to. Decided once, at
  /// extraction time, from [type] (or document content for Knowledge
  /// documents) — never re-derived per department downstream.
  final Set<Department> visibleTo;
}
