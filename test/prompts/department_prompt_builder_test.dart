import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_snapshot.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:test/test.dart';

DepartmentSnapshot _snapshot(Department department) {
  return DepartmentSnapshot(
    department: department,
    company: ['overview: We build software.'],
    knowledge: ['playbook: SEO and campaign playbook.'],
    products: ['petsupo: A pet care marketplace.'],
    assets: [],
    services: [],
    websites: [],
    social: [],
    analytics: [],
    knownData: ['Company', 'Knowledge', 'Products'],
    missingData: ['Assets'],
    blockedItems: [
      '${department.displayName} cannot fully plan today without Assets '
          'data — it is not yet connected.',
    ],
    evidence: [],
  );
}

void main() {
  test('build() generates identical prompts for identical snapshots and '
      'dates', () {
    const builder = DepartmentPromptBuilder();
    final date = DateTime(2026, 7, 20);

    final first = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: date,
    );
    final second = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: date,
    );

    expect(first, second);
  });

  test('build() includes the department name and grounded content', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('Marketing Snapshot:'));
    expect(prompt, contains('A pet care marketplace.'));
    expect(prompt, contains("write today's Marketing Priorities"));
    expect(prompt, contains('Known Data: Company, Knowledge, Products'));
    expect(prompt, contains('Missing Data: Assets'));
  });

  test('build() contains hallucination-prevention instructions', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(Department.engineering),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('Never invent facts'));
    expect(prompt, contains('KPIs'));
    expect(prompt, contains('campaigns'));
    expect(prompt, contains('business metrics'));
  });

  test('buildReport() composes one section per department, in order', () {
    const builder = DepartmentPromptBuilder();
    final snapshots = Department.values.map(_snapshot).toList();

    final report = builder.buildReport(
      snapshots: snapshots,
      currentDate: DateTime(2026, 7, 20),
    );

    for (final department in Department.values) {
      expect(report, contains('${department.displayName} Snapshot:'));
      expect(report, contains("Today's ${department.displayName} Priorities"));
    }
  });

  test('buildReport() instructs the model not to render Runtime-owned '
      'sections', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      snapshots: [_snapshot(Department.finance)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('Blocked Items'));
    expect(report, contains('Runtime appends them automatically'));
  });

  test('buildReport() includes the current date', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      snapshots: [_snapshot(Department.sales)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('2026-07-20'));
  });
}
