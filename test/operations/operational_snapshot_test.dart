import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
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
  visibleTo: const {Department.executive, Department.marketing},
);

void main() {
  test('build() splits states into allowed (existence-only entities) and '
      'blocked (entities with unresolved readiness signals)', () {
    final departmentFacts = DepartmentFacts(
      department: Department.marketing,
      facts: [
        _fact(FactType.brandAsset, 'Brand Kit'),
        _fact(FactType.website, 'petsupo.com'),
      ],
      knownTypes: const [FactType.brandAsset, FactType.website],
      missingTypes: const [],
    );
    const graph = KnowledgeGraph(facts: []);

    final snapshot = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );

    expect(snapshot.allowed.map((s) => s.name), ['Brand Kit']);
    expect(snapshot.blocked, hasLength(1));
    expect(snapshot.blocked.single.state.name, 'petsupo.com');
  });

  test('build() reports missing operational data as the union of every '
      'blocked state\'s missing signals', () {
    final departmentFacts = DepartmentFacts(
      department: Department.marketing,
      facts: [_fact(FactType.website, 'petsupo.com')],
      knownTypes: const [FactType.website],
      missingTypes: const [],
    );
    const graph = KnowledgeGraph(facts: []);

    final snapshot = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );

    expect(snapshot.missingOperationalData, contains('reachable'));
    expect(snapshot.missingOperationalData, contains('lastDeploy'));
  });

  test('build() never reports missing operational data for a department '
      'with no facts at all', () {
    final departmentFacts = DepartmentFacts(
      department: Department.sales,
      facts: const [],
      knownTypes: const [],
      missingTypes: const [FactType.product],
    );
    const graph = KnowledgeGraph(facts: []);

    final snapshot = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );

    expect(snapshot.missingOperationalData, isEmpty);
    expect(snapshot.observabilityScore, 0.0);
  });

  test('build() computes the observability score as the mean completeness '
      'across every state in the department', () {
    final departmentFacts = DepartmentFacts(
      department: Department.marketing,
      facts: [_fact(FactType.brandAsset, 'Brand Kit')],
      knownTypes: const [FactType.brandAsset],
      missingTypes: const [],
    );
    const graph = KnowledgeGraph(facts: []);

    final snapshot = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );

    expect(snapshot.observabilityScore, 1.0);
  });

  test('build() is deterministic', () {
    final departmentFacts = DepartmentFacts(
      department: Department.marketing,
      facts: [_fact(FactType.website, 'petsupo.com')],
      knownTypes: const [FactType.website],
      missingTypes: const [],
    );
    const graph = KnowledgeGraph(facts: []);

    final first = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );
    final second = OperationalSnapshot.build(
      departmentFacts: departmentFacts,
      graph: graph,
    );

    expect(first.observabilityScore, second.observabilityScore);
    expect(first.missingOperationalData, second.missingOperationalData);
    expect(first.allowed.length, second.allowed.length);
    expect(first.blocked.length, second.blocked.length);
  });
}
