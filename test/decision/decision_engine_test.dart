import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/decision/decision_engine.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_rule.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:test/test.dart';

CompanyFact _fact(FactType type, String name) => CompanyFact(
  id: '${type.name}:$name',
  type: type,
  name: name,
  attributes: const {},
  sources: const [],
  extractionRule: 'test',
  confidence: 1.0,
  visibleTo: const {
    Department.executive,
    Department.marketing,
    Department.engineering,
  },
);

OperationalSnapshot _snapshotFor(
  Department department,
  List<CompanyFact> facts, {
  List<FactType> missingTypes = const [],
}) {
  final departmentFacts = DepartmentFacts(
    department: department,
    facts: facts,
    knownTypes: facts.map((f) => f.type).toSet().toList(),
    missingTypes: missingTypes,
  );
  final graph = KnowledgeGraph(facts: facts);

  return OperationalSnapshot.build(
    departmentFacts: departmentFacts,
    graph: graph,
  );
}

void main() {
  group('default rules', () {
    test('generate() creates a Connect GA4 decision for Marketing when a '
        'Website has no analytics connected', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
      ]);

      final decisions = engine.generate(snapshot);

      expect(decisions.map((d) => d.title), contains('Connect GA4'));
      final decision = decisions.firstWhere((d) => d.title == 'Connect GA4');
      expect(decision.department, Department.marketing);
      expect(decision.type, DecisionType.connect);
      expect(decision.blocked, isFalse);
      expect(decision.evidence, contains(FactType.website));
      expect(decision.evidence, contains(FactType.analyticsPlatform));
    });

    test('generate() does not create a Connect GA4 decision when analytics '
        'is already connected', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
        _fact(FactType.analyticsPlatform, 'GA4'),
      ]);

      final decisions = engine.generate(snapshot);

      expect(decisions.map((d) => d.title), isNot(contains('Connect GA4')));
    });

    test('generate() creates a blocker decision for Campaign Optimization '
        'when campaign assets are ready but analytics is missing', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
        _fact(FactType.brandAsset, 'Brand Kit'),
        _fact(FactType.mediaAsset, 'Hero Video'),
      ]);

      final decisions = engine.generate(snapshot);

      final blocker = decisions.firstWhere(
        (d) => d.title == 'Campaign Optimization',
      );
      expect(blocker.blocked, isTrue);
      expect(blocker.type, DecisionType.blocker);
      expect(
        blocker.reasons.map((r) => r.statement),
        contains('Analytics unavailable'),
      );
    });

    test('generate() creates a Critical "Create brand assets" decision when '
        'a Product exists but brand assets are entirely missing', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(
        Department.marketing,
        [_fact(FactType.product, 'Petsupo')],
        missingTypes: const [FactType.brandAsset],
      );

      final decisions = engine.generate(snapshot);

      final decision = decisions.firstWhere(
        (d) => d.title == 'Create brand assets',
      );
      expect(decision.priority.name, 'critical');
    });

    test('generate() creates a "Prepare launch campaign" decision when '
        'Product, BrandAsset, and MediaAsset all exist', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.product, 'Petsupo'),
        _fact(FactType.brandAsset, 'Brand Kit'),
        _fact(FactType.mediaAsset, 'Hero Video'),
      ]);

      final decisions = engine.generate(snapshot);

      expect(
        decisions.map((d) => d.title),
        contains('Prepare launch campaign'),
      );
    });

    test('generate() creates a Connect CI decision for Engineering when a '
        'Repository has no known CI status', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.engineering, [
        _fact(FactType.repository, 'pharos-runtime'),
      ]);

      final decisions = engine.generate(snapshot);

      expect(decisions.map((d) => d.title), contains('Connect CI'));
    });

    test('generate() produces no decisions for a department with no '
        'relevant facts', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.finance, const []);

      final decisions = engine.generate(snapshot);

      expect(decisions, isEmpty);
    });
  });

  group('scoring', () {
    test('impact and urgency are carried through to the decision score', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
      ]);

      final decision = engine
          .generate(snapshot)
          .firstWhere((d) => d.title == 'Connect GA4');

      expect(decision.score.impact, 0.9);
      expect(decision.score.urgency, 0.9);
    });

    test("confidence reflects the rule's evidence completeness", () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
      ]);

      final decision = engine
          .generate(snapshot)
          .firstWhere((d) => d.title == 'Connect GA4');

      expect(decision.confidence, 1.0);
    });
  });

  group('ranking and limits', () {
    test(
      'generate() caps priorities, blockers, and informational notes at 3 each',
      () {
        final rules = [
          for (var i = 0; i < 5; i++)
            DecisionRule(
              id: 'priority.$i',
              department: Department.marketing,
              type: DecisionType.connect,
              title: 'Priority $i',
              impact: 0.1 * (i + 1),
              urgency: 1.0,
              appliesTo: (_) => true,
              reasonsFor: (_) => const [DecisionReason('synthetic')],
              evidenceFor: (_) => const [FactType.product],
            ),
          for (var i = 0; i < 5; i++)
            DecisionRule(
              id: 'blocker.$i',
              department: Department.marketing,
              type: DecisionType.blocker,
              title: 'Blocker $i',
              impact: 0.1 * (i + 1),
              urgency: 1.0,
              appliesTo: (_) => true,
              reasonsFor: (_) => const [DecisionReason('synthetic')],
              evidenceFor: (_) => const [FactType.product],
            ),
          for (var i = 0; i < 5; i++)
            DecisionRule(
              id: 'note.$i',
              department: Department.marketing,
              type: DecisionType.review,
              title: 'Note $i',
              impact: 0.1 * (i + 1),
              urgency: 1.0,
              appliesTo: (_) => true,
              reasonsFor: (_) => const [DecisionReason('synthetic')],
              evidenceFor: (_) => const [FactType.product],
            ),
        ];
        final engine = DecisionEngine(rules: rules);
        final snapshot = _snapshotFor(Department.marketing, const []);

        final decisions = engine.generate(snapshot);

        expect(decisions.where((d) => d.blocked).length, 3);
        expect(
          decisions
              .where((d) => !d.blocked && DecisionEngine.isActionable(d.type))
              .length,
          3,
        );
        expect(
          decisions
              .where((d) => !d.blocked && !DecisionEngine.isActionable(d.type))
              .length,
          3,
        );
        expect(decisions.length, 9);
      },
    );

    test(
      'generate() ranks decisions by score descending within each category',
      () {
        final rules = [
          for (var i = 0; i < 3; i++)
            DecisionRule(
              id: 'priority.$i',
              department: Department.marketing,
              type: DecisionType.connect,
              title: 'Priority $i',
              impact: 0.1 * (i + 1),
              urgency: 1.0,
              appliesTo: (_) => true,
              reasonsFor: (_) => const [DecisionReason('synthetic')],
              evidenceFor: (_) => const [FactType.product],
            ),
        ];
        final engine = DecisionEngine(rules: rules);
        final snapshot = _snapshotFor(Department.marketing, const []);

        final decisions = engine.generate(snapshot);

        expect(decisions.map((d) => d.title).toList(), [
          'Priority 2',
          'Priority 1',
          'Priority 0',
        ]);
      },
    );

    test('generate() breaks score ties deterministically by id', () {
      final rules = [
        DecisionRule(
          id: 'zzz',
          department: Department.marketing,
          type: DecisionType.connect,
          title: 'Zzz',
          impact: 0.5,
          urgency: 1.0,
          appliesTo: (_) => true,
          reasonsFor: (_) => const [DecisionReason('synthetic')],
          evidenceFor: (_) => const [FactType.product],
        ),
        DecisionRule(
          id: 'aaa',
          department: Department.marketing,
          type: DecisionType.connect,
          title: 'Aaa',
          impact: 0.5,
          urgency: 1.0,
          appliesTo: (_) => true,
          reasonsFor: (_) => const [DecisionReason('synthetic')],
          evidenceFor: (_) => const [FactType.product],
        ),
      ];
      final engine = DecisionEngine(rules: rules);
      final snapshot = _snapshotFor(Department.marketing, const []);

      final decisions = engine.generate(snapshot);

      expect(decisions.map((d) => d.title).toList(), ['Aaa', 'Zzz']);
    });

    test('generate() is deterministic across repeated calls', () {
      const engine = DecisionEngine();
      final snapshot = _snapshotFor(Department.marketing, [
        _fact(FactType.website, 'petsupo.com'),
        _fact(FactType.product, 'Petsupo'),
        _fact(FactType.brandAsset, 'Brand Kit'),
        _fact(FactType.mediaAsset, 'Hero Video'),
      ]);

      final first = engine.generate(snapshot);
      final second = engine.generate(snapshot);

      expect(first.map((d) => d.id).toList(), second.map((d) => d.id).toList());
    });
  });
}
