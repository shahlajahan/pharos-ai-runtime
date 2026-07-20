import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:test/test.dart';

CompanyFact _productFact() => const CompanyFact(
  id: 'product:petsupo',
  type: FactType.product,
  name: 'Petsupo',
  attributes: {},
  sources: ['products/petsupo'],
  extractionRule: 'product-from-category',
  confidence: 1.0,
  visibleTo: {Department.executive, Department.marketing},
);

DepartmentFacts _departmentFacts(Department department) => DepartmentFacts(
  department: department,
  facts: [_productFact()],
  knownTypes: [FactType.product],
  missingTypes: [FactType.analyticsPlatform],
);

void main() {
  test('build() generates identical prompts for identical DepartmentFacts '
      'and dates', () {
    const builder = DepartmentPromptBuilder();
    final date = DateTime(2026, 7, 20);

    final first = builder.build(
      departmentFacts: _departmentFacts(Department.marketing),
      currentDate: date,
    );
    final second = builder.build(
      departmentFacts: _departmentFacts(Department.marketing),
      currentDate: date,
    );

    expect(first, second);
  });

  test('build() includes only structured facts, never raw markdown', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      departmentFacts: _departmentFacts(Department.marketing),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('Marketing Facts:'));
    expect(prompt, contains('Product: Petsupo'));
    expect(prompt, contains('Missing Facts: Analytics Platform'));
    expect(prompt, isNot(contains('products/petsupo')));
    expect(prompt, isNot(contains('#')));
  });

  test('build() requires every recommendation to cite evidence and a '
      'confidence level', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      departmentFacts: _departmentFacts(Department.engineering),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('cite the CompanyFact type'));
    expect(prompt, contains('Confidence level'));
    expect(prompt, contains('Never make a recommendation without evidence'));
  });

  test('buildReport() composes one Facts section per department, in order', () {
    const builder = DepartmentPromptBuilder();
    final allFacts = Department.values.map(_departmentFacts).toList();

    final report = builder.buildReport(
      departmentFacts: allFacts,
      currentDate: DateTime(2026, 7, 20),
    );

    for (final department in Department.values) {
      expect(report, contains('${department.displayName} Facts:'));
      expect(report, contains("Today's ${department.displayName} Priorities"));
    }
  });

  test('buildReport() instructs the model not to render Runtime-owned '
      'sections', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      departmentFacts: [_departmentFacts(Department.finance)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('Blocked Items'));
    expect(report, contains('Runtime appends them automatically'));
  });

  test('buildReport() includes the current date', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      departmentFacts: [_departmentFacts(Department.sales)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('2026-07-20'));
  });
}
