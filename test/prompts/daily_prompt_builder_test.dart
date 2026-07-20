import 'package:pharos_ai_runtime/company/company_snapshot.dart';
import 'package:pharos_ai_runtime/prompts/daily_prompt_builder.dart';
import 'package:test/test.dart';

CompanySnapshot _snapshot() => const CompanySnapshot(
  company: ['overview: We build software.'],
  products: ['petsupo: A pet care marketplace.'],
  capabilities: ['flutter: Clean architecture.'],
  assets: [],
  websites: [],
  analytics: [],
  social: [],
  services: [],
  knownData: ['Company', 'Products', 'Knowledge'],
  missingData: ['Assets', 'Websites', 'Analytics', 'Social', 'Services'],
  risks: [
    'Assets data is not connected — related decisions carry '
        'additional uncertainty.',
  ],
  recommendationsInput: [
    'petsupo: A pet care marketplace.',
    'flutter: Clean architecture.',
  ],
);

void main() {
  test('build() generates identical prompts for identical snapshots, dates, '
      'and workflow goals', () {
    const builder = DailyPromptBuilder();
    final currentDate = DateTime(2026, 7, 20);

    final first = builder.build(
      snapshot: _snapshot(),
      currentDate: currentDate,
      workflowGoal: 'Generate the daily executive report.',
    );
    final second = builder.build(
      snapshot: _snapshot(),
      currentDate: currentDate,
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(first, second);
  });

  test('build() produces a different prompt for a different current date', () {
    const builder = DailyPromptBuilder();

    final first = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 20),
      workflowGoal: 'Generate the daily executive report.',
    );
    final second = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 21),
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(first, isNot(second));
  });

  test('build() includes the current date and workflow goal', () {
    const builder = DailyPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 20),
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(prompt, contains('2026-07-20'));
    expect(prompt, contains('Generate the daily executive report.'));
  });

  test('build() includes the CompanySnapshot content, not raw documents', () {
    const builder = DailyPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 20),
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(prompt, contains('A pet care marketplace.'));
    expect(prompt, contains('Clean architecture.'));
    expect(prompt, contains('Known Data: Company, Products, Knowledge'));
    expect(
      prompt,
      contains('Missing Data: Assets, Websites, Analytics, Social, Services'),
    );
  });

  test('build() prompt contains all hallucination-prevention rules', () {
    const builder = DailyPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 20),
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(prompt, contains('Reason only over the Company Snapshot'));
    expect(prompt, contains('Never invent company facts'));
    expect(prompt, contains('Never invent KPIs'));
    expect(prompt, contains('Never invent campaigns'));
    expect(prompt, contains('Never invent analytics'));
    expect(prompt, contains('Never invent revenue'));
    expect(prompt, contains('unavailable'));
    expect(prompt, contains('Known'));
    expect(prompt, contains('Unknown'));
    expect(prompt, contains('Recommendation'));
  });

  test('build() instructs the model to produce the Executive Report '
      'sections, but not the Data Sources Used section', () {
    const builder = DailyPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(),
      currentDate: DateTime(2026, 7, 20),
      workflowGoal: 'Generate the daily executive report.',
    );

    expect(prompt, contains('Executive Summary'));
    expect(prompt, contains('Business Assets'));
    expect(prompt, contains('Current Capabilities'));
    expect(prompt, contains('Known Information'));
    expect(prompt, contains('Missing Information'));
    expect(prompt, contains("Today's Priorities"));
    expect(prompt, contains('Recommended Next Actions'));
    expect(prompt, contains('Do not include a "Data Sources Used" section'));
  });
}
