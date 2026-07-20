import 'package:pharos_ai_runtime/company/company_document.dart';
import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// Extracts deterministic CompanyFacts from CompanyDocuments. Only
/// structural rules based on HQ category and document name — no NLP, no
/// embeddings, no LLM calls, no summarizing, no inferring. A document
/// whose category is not recognized produces no fact at all, rather than
/// a guessed one. FactExtractor is the only place HQ document content is
/// ever read; nothing downstream sees raw markdown.
class FactExtractor {
  const FactExtractor();

  static const Set<Department> _allDepartments = {
    Department.executive,
    Department.engineering,
    Department.marketing,
    Department.sales,
    Department.operations,
    Department.finance,
  };

  /// Departments whose vocabulary a Knowledge document's content matches.
  /// Executive always sees every Knowledge document, since its job is
  /// spotting cross-department blockers.
  static const Map<Department, List<String>> _capabilityKeywords = {
    Department.marketing: [
      'marketing',
      'seo',
      'brand',
      'campaign',
      'social',
      'competitor',
      'advertising',
      'content',
      'market research',
      'audience',
    ],
    Department.engineering: [
      'engineering',
      'architecture',
      'infrastructure',
      'repository',
      'developer',
      'technical',
      'backend',
      'frontend',
      'api',
      'flutter',
      'dart',
      'code',
    ],
    Department.sales: [
      'sales',
      'lead',
      'crm',
      'pipeline',
      'partnership',
      'deal',
      'prospect',
    ],
    Department.operations: [
      'operations',
      'workflow',
      'process',
      'automation',
      'logistics',
      'support',
    ],
    Department.finance: [
      'finance',
      'billing',
      'subscription',
      'payment',
      'revenue',
      'invoice',
      'budget',
      'cost',
      'accounting',
    ],
  };

  List<CompanyFact> extract(List<CompanyDocument> documents) => [
    for (final document in documents) ..._extractFrom(document),
  ];

  List<CompanyFact> _extractFrom(CompanyDocument document) {
    switch (document.category) {
      case 'company':
        return [
          _fact(
            document: document,
            type: FactType.company,
            idPrefix: 'company',
            visibleTo: _allDepartments,
            extractionRule: 'company-from-category',
          ),
        ];
      case 'knowledge':
        return [
          _fact(
            document: document,
            type: FactType.capability,
            idPrefix: 'capability',
            visibleTo: _capabilityVisibility(document.content),
            extractionRule: 'capability-from-category',
          ),
        ];
      case 'products':
        return [
          _fact(
            document: document,
            type: FactType.product,
            idPrefix: 'product',
            visibleTo: const {
              Department.executive,
              Department.marketing,
              Department.engineering,
              Department.sales,
            },
            extractionRule: 'product-from-category',
          ),
        ];
      case 'assets':
        return _extractAssetFacts(document);
      case 'services':
        return [
          _fact(
            document: document,
            type: FactType.service,
            idPrefix: 'service',
            visibleTo: const {Department.executive, Department.engineering},
            extractionRule: 'service-from-category',
          ),
        ];
      case 'websites':
        return _websiteFacts(document, extractionRule: 'website-from-category');
      case 'social':
        return [
          _fact(
            document: document,
            type: FactType.socialAccount,
            idPrefix: 'social-account',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'social-account-from-category',
          ),
        ];
      case 'analytics':
        return [
          _fact(
            document: document,
            type: FactType.analyticsPlatform,
            idPrefix: 'analytics-platform',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'analytics-platform-from-category',
          ),
        ];
      default:
        return const [];
    }
  }

  /// Real HQ assets are organized into subfolders (`assets/websites`,
  /// `assets/social`, `assets/finance`, ...) rather than living flat
  /// under `assets/`. Dispatch on the first path segment below `assets`
  /// so each subfolder becomes its own fact type; a document directly
  /// under `assets/` (or in an unrecognized subfolder) falls back to the
  /// original brand/media heuristic.
  List<CompanyFact> _extractAssetFacts(CompanyDocument document) {
    final segments = document.path.split('/');
    final subfolder = segments.length > 1 ? segments.first : null;

    switch (subfolder) {
      case 'websites':
        return _websiteFacts(
          document,
          extractionRule: 'website-from-assets-subfolder',
        );
      case 'domains':
        return [
          _fact(
            document: document,
            type: FactType.domain,
            idPrefix: 'domain',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'domain-from-assets-subfolder',
          ),
        ];
      case 'social':
        return [
          _fact(
            document: document,
            type: FactType.socialAccount,
            idPrefix: 'social-account',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'social-account-from-assets-subfolder',
          ),
        ];
      case 'analytics':
        return [
          _fact(
            document: document,
            type: FactType.analyticsPlatform,
            idPrefix: 'analytics-platform',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'analytics-platform-from-assets-subfolder',
          ),
        ];
      case 'services':
        return [
          _fact(
            document: document,
            type: FactType.service,
            idPrefix: 'service',
            visibleTo: const {Department.executive, Department.engineering},
            extractionRule: 'service-from-assets-subfolder',
          ),
        ];
      case 'brand':
        return [
          _fact(
            document: document,
            type: FactType.brandAsset,
            idPrefix: 'brand-asset',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'brand-asset-from-assets-subfolder',
          ),
        ];
      case 'media':
        return [
          _fact(
            document: document,
            type: FactType.mediaAsset,
            idPrefix: 'media-asset',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'media-asset-from-assets-subfolder',
          ),
        ];
      case 'seo':
        return [
          _fact(
            document: document,
            type: FactType.seoAsset,
            idPrefix: 'seo-asset',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'seo-asset-from-assets-subfolder',
          ),
        ];
      case 'ads':
        return [
          _fact(
            document: document,
            type: FactType.advertisingPlatform,
            idPrefix: 'advertising-platform',
            visibleTo: const {Department.executive, Department.marketing},
            extractionRule: 'advertising-platform-from-assets-subfolder',
          ),
        ];
      case 'accounts':
        return [
          _fact(
            document: document,
            type: FactType.account,
            idPrefix: 'account',
            visibleTo: const {Department.executive, Department.finance},
            extractionRule: 'account-from-assets-subfolder',
          ),
        ];
      case 'infrastructure':
        return [
          _fact(
            document: document,
            type: FactType.infrastructure,
            idPrefix: 'infrastructure',
            visibleTo: const {
              Department.executive,
              Department.engineering,
              Department.operations,
            },
            extractionRule: 'infrastructure-from-assets-subfolder',
          ),
        ];
      case 'crm':
        return [
          _fact(
            document: document,
            type: FactType.account,
            idPrefix: 'crm-account',
            visibleTo: const {Department.executive, Department.sales},
            extractionRule: 'crm-account-from-assets-subfolder',
          ),
        ];
      case 'finance':
        return [_financeAssetFact(document)];
      default:
        return [_legacyAssetFact(document)];
    }
  }

  /// A website document also implies a Domain fact whenever its name
  /// already looks like one (contains a literal dot) — never guessed
  /// beyond that structural check.
  List<CompanyFact> _websiteFacts(
    CompanyDocument document, {
    required String extractionRule,
  }) {
    final facts = [
      _fact(
        document: document,
        type: FactType.website,
        idPrefix: 'website',
        visibleTo: const {Department.executive, Department.marketing},
        extractionRule: extractionRule,
      ),
    ];

    if (document.name.contains('.')) {
      facts.add(
        _fact(
          document: document,
          type: FactType.domain,
          idPrefix: 'domain',
          visibleTo: const {Department.executive, Department.marketing},
          extractionRule: 'domain-from-website-name',
        ),
      );
    }

    return facts;
  }

  /// `assets/finance` mixes payment providers and finance accounts;
  /// split deterministically by document name rather than treating the
  /// whole subfolder as one fact type.
  CompanyFact _financeAssetFact(CompanyDocument document) {
    final lowerName = document.name.toLowerCase();

    if (lowerName.contains('payment')) {
      return _fact(
        document: document,
        type: FactType.paymentProvider,
        idPrefix: 'payment-provider',
        visibleTo: const {Department.executive, Department.finance},
        extractionRule: 'payment-provider-from-finance-subfolder',
      );
    }

    if (lowerName.contains('account')) {
      return _fact(
        document: document,
        type: FactType.account,
        idPrefix: 'finance-account',
        visibleTo: const {Department.executive, Department.finance},
        extractionRule: 'account-from-finance-subfolder',
      );
    }

    return _fact(
      document: document,
      type: FactType.subscription,
      idPrefix: 'finance-subscription',
      visibleTo: const {Department.executive, Department.finance},
      extractionRule: 'subscription-from-finance-subfolder',
    );
  }

  /// Preserves the original HQ-040 behavior for assets with no
  /// recognized subfolder (including flat files directly under
  /// `assets/`).
  CompanyFact _legacyAssetFact(CompanyDocument document) {
    final isBrand = document.name.toLowerCase().contains('brand');

    return _fact(
      document: document,
      type: isBrand ? FactType.brandAsset : FactType.mediaAsset,
      idPrefix: isBrand ? 'brand-asset' : 'media-asset',
      visibleTo: const {Department.executive, Department.marketing},
      extractionRule: isBrand
          ? 'brand-asset-from-name'
          : 'media-asset-from-category',
    );
  }

  Set<Department> _capabilityVisibility(String content) {
    final lowerContent = content.toLowerCase();
    final visibleTo = <Department>{Department.executive};

    for (final entry in _capabilityKeywords.entries) {
      if (entry.value.any(lowerContent.contains)) {
        visibleTo.add(entry.key);
      }
    }

    return visibleTo;
  }

  CompanyFact _fact({
    required CompanyDocument document,
    required FactType type,
    required String idPrefix,
    required Set<Department> visibleTo,
    required String extractionRule,
  }) {
    return CompanyFact(
      id: '$idPrefix:${_slug(document.name)}',
      type: type,
      name: document.name,
      attributes: const {},
      sources: ['${document.category}/${document.path}'],
      extractionRule: extractionRule,
      confidence: 1.0,
      visibleTo: visibleTo,
    );
  }

  String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
