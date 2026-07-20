import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_rule.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';

/// Evaluates operational readiness, calculates business impact,
/// identifies blockers, and prioritizes work — deterministically. The
/// LLM never decides what is important; it only ever explains what the
/// Decision Engine has already ranked. Each department is capped at
/// [decisionLimitPerCategory] priorities, blockers, and informational
/// notes: the Runtime performs ranking before the LLM ever sees a word.
class DecisionEngine {
  const DecisionEngine({this.rules = defaultRules});

  final List<DecisionRule> rules;

  static const int decisionLimitPerCategory = 3;

  /// Decision types treated as actionable "priorities". Every other
  /// non-blocked type is rendered as an informational note.
  static const Set<DecisionType> _actionableTypes = {
    DecisionType.launch,
    DecisionType.improve,
    DecisionType.connect,
    DecisionType.fix,
  };

  static bool isActionable(DecisionType type) =>
      _actionableTypes.contains(type);

  List<Decision> generate(OperationalSnapshot snapshot) {
    final candidates = [
      for (final rule in rules)
        if (rule.department == snapshot.department && rule.appliesTo(snapshot))
          _decisionFrom(rule, snapshot),
    ];

    return _rankAndLimit(candidates);
  }

  Decision _decisionFrom(DecisionRule rule, OperationalSnapshot snapshot) {
    final score = DecisionScore(
      impact: rule.impact,
      urgency: rule.urgency,
      evidenceCompleteness: rule.evidenceCompleteness(snapshot),
    );

    return Decision(
      id: '${snapshot.department.name}.${rule.id}',
      department: snapshot.department,
      title: rule.title,
      type: rule.type,
      priority: DecisionPriority.fromScore(score.value),
      score: score,
      blocked: rule.type == DecisionType.blocker,
      reasons: rule.reasonsFor(snapshot),
      evidence: rule.evidenceFor(snapshot),
    );
  }

  List<Decision> _rankAndLimit(List<Decision> decisions) {
    final blockers = _topRanked(decisions.where((d) => d.blocked));
    final priorities = _topRanked(
      decisions.where((d) => !d.blocked && isActionable(d.type)),
    );
    final informational = _topRanked(
      decisions.where((d) => !d.blocked && !isActionable(d.type)),
    );

    return [...blockers, ...priorities, ...informational];
  }

  /// Ranked by score, highest first; ties broken by id for deterministic
  /// ordering regardless of input order.
  List<Decision> _topRanked(Iterable<Decision> decisions) {
    final sorted = decisions.toList()
      ..sort((a, b) {
        final byScore = b.score.value.compareTo(a.score.value);
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });

    return sorted.take(decisionLimitPerCategory).toList();
  }

  // --- Default rules -------------------------------------------------
  //
  // Every predicate below only ever fires on a deterministically
  // resolved signal (yes/no, or a fact type's confirmed absence) — never
  // on an unknown one — which is why every default rule's evidence is
  // fully known (evidenceCompleteness defaults to 1.0).

  static const List<DecisionRule> defaultRules = [
    DecisionRule(
      id: 'analytics.connect',
      department: Department.marketing,
      type: DecisionType.connect,
      title: 'Connect GA4',
      impact: 0.9,
      urgency: 0.9,
      appliesTo: _analyticsMissing,
      reasonsFor: _analyticsMissingReasons,
      evidenceFor: _analyticsMissingEvidence,
    ),
    DecisionRule(
      id: 'campaign.blocked',
      department: Department.marketing,
      type: DecisionType.blocker,
      title: 'Campaign Optimization',
      impact: 0.9,
      urgency: 0.9,
      appliesTo: _campaignBlockedByAnalytics,
      reasonsFor: _campaignBlockedReasons,
      evidenceFor: _analyticsMissingEvidence,
    ),
    DecisionRule(
      id: 'brand.create',
      department: Department.marketing,
      type: DecisionType.fix,
      title: 'Create brand assets',
      impact: 0.9,
      urgency: 1.0,
      appliesTo: _brandAssetsMissing,
      reasonsFor: _brandAssetsMissingReasons,
      evidenceFor: _productEvidence,
    ),
    DecisionRule(
      id: 'launch.prepare',
      department: Department.marketing,
      type: DecisionType.launch,
      title: 'Prepare launch campaign',
      impact: 0.8,
      urgency: 0.7,
      appliesTo: _launchReady,
      reasonsFor: _launchReadyReasons,
      evidenceFor: _launchReadyEvidence,
    ),
    DecisionRule(
      id: 'ci.connect',
      department: Department.engineering,
      type: DecisionType.connect,
      title: 'Connect CI',
      impact: 0.75,
      urgency: 0.75,
      appliesTo: _ciMissing,
      reasonsFor: _ciMissingReasons,
      evidenceFor: _repositoryEvidence,
    ),
    DecisionRule(
      id: 'documentation.review',
      department: Department.engineering,
      type: DecisionType.review,
      title: 'Review documentation coverage',
      impact: 0.4,
      urgency: 0.3,
      appliesTo: _documentationMissing,
      reasonsFor: _documentationMissingReasons,
      evidenceFor: _repositoryEvidence,
    ),
  ];

  static bool _hasType(OperationalSnapshot snapshot, FactType type) =>
      snapshot.states.any((state) => state.factType == type);

  static bool _isMissingType(OperationalSnapshot snapshot, FactType type) =>
      snapshot.missingFactTypes.contains(type);

  static bool _signalEquals(
    OperationalSnapshot snapshot,
    FactType type,
    String signal,
    SignalState value,
  ) => snapshot.states
      .where((state) => state.factType == type)
      .any((state) => state.signals[signal] == value);

  static bool _analyticsMissing(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.website) &&
      _signalEquals(
        snapshot,
        FactType.website,
        'analyticsConnected',
        SignalState.no,
      );

  static List<DecisionReason> _analyticsMissingReasons(
    OperationalSnapshot snapshot,
  ) => [
    const DecisionReason('Website exists'),
    if (_hasType(snapshot, FactType.brandAsset))
      const DecisionReason('Brand assets ready'),
    if (_hasType(snapshot, FactType.mediaAsset))
      const DecisionReason('Campaign assets ready'),
    const DecisionReason('Analytics unavailable'),
  ];

  static List<FactType> _analyticsMissingEvidence(
    OperationalSnapshot snapshot,
  ) => [
    FactType.website,
    if (_hasType(snapshot, FactType.brandAsset)) FactType.brandAsset,
    FactType.analyticsPlatform,
  ];

  static bool _campaignBlockedByAnalytics(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.brandAsset) &&
      _hasType(snapshot, FactType.mediaAsset) &&
      _signalEquals(
        snapshot,
        FactType.website,
        'analyticsConnected',
        SignalState.no,
      );

  static List<DecisionReason> _campaignBlockedReasons(
    OperationalSnapshot snapshot,
  ) => const [DecisionReason('Analytics unavailable')];

  static bool _brandAssetsMissing(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.product) &&
      _isMissingType(snapshot, FactType.brandAsset);

  static List<DecisionReason> _brandAssetsMissingReasons(
    OperationalSnapshot snapshot,
  ) => const [
    DecisionReason('Product exists'),
    DecisionReason('Brand assets missing'),
  ];

  static List<FactType> _productEvidence(OperationalSnapshot snapshot) =>
      const [FactType.product];

  static bool _launchReady(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.product) &&
      _hasType(snapshot, FactType.brandAsset) &&
      _hasType(snapshot, FactType.mediaAsset);

  static List<DecisionReason> _launchReadyReasons(
    OperationalSnapshot snapshot,
  ) => const [
    DecisionReason('Product exists'),
    DecisionReason('Brand assets ready'),
    DecisionReason('Media assets ready'),
  ];

  static List<FactType> _launchReadyEvidence(OperationalSnapshot snapshot) =>
      const [FactType.product, FactType.brandAsset, FactType.mediaAsset];

  static bool _ciMissing(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.repository) &&
      _signalEquals(
        snapshot,
        FactType.repository,
        'ciStatus',
        SignalState.unknown,
      );

  static List<DecisionReason> _ciMissingReasons(OperationalSnapshot snapshot) =>
      const [
        DecisionReason('Repository exists'),
        DecisionReason('CI status unavailable'),
      ];

  static List<FactType> _repositoryEvidence(OperationalSnapshot snapshot) =>
      const [FactType.repository];

  static bool _documentationMissing(OperationalSnapshot snapshot) =>
      _hasType(snapshot, FactType.repository) &&
      _signalEquals(
        snapshot,
        FactType.repository,
        'documentationCoverage',
        SignalState.unknown,
      );

  static List<DecisionReason> _documentationMissingReasons(
    OperationalSnapshot snapshot,
  ) => const [
    DecisionReason('Repository exists'),
    DecisionReason('Documentation coverage unavailable'),
  ];
}
