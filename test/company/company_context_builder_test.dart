import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/company_context_builder.dart';
import 'package:pharos_ai_runtime/company/company_document.dart';
import 'package:test/test.dart';

void main() {
  test('build() groups documents into the correct sections', () {
    const builder = CompanyContextBuilder();
    const documents = [
      CompanyDocument(
        category: 'company',
        name: 'overview',
        content: 'We build software.',
      ),
      CompanyDocument(
        category: 'products',
        name: 'petsupo',
        content: 'A pet care marketplace.',
      ),
      CompanyDocument(
        category: 'products',
        name: 'devaudit',
        content: 'A code auditing tool.',
      ),
    ];

    final context = builder.build(documents);

    expect(context.company, ['overview: We build software.']);
    expect(context.products, [
      'petsupo: A pet care marketplace.',
      'devaudit: A code auditing tool.',
    ]);
    expect(context.knowledge, isEmpty);
    expect(context.assets, isEmpty);
    expect(context.services, isEmpty);
    expect(context.websites, isEmpty);
    expect(context.social, isEmpty);
    expect(context.analytics, isEmpty);
  });

  test('build() strips markdown heading markers from content', () {
    const builder = CompanyContextBuilder();
    const documents = [
      CompanyDocument(
        category: 'company',
        name: 'overview',
        content: '# Overview\n\nWe build software.',
      ),
    ];

    final context = builder.build(documents);

    expect(context.company.single, isNot(contains('#')));
    expect(context.company.single, contains('We build software.'));
  });

  test('build() returns an empty CompanyContext for no documents', () {
    const builder = CompanyContextBuilder();

    final context = builder.build(const []);

    expect(context.company, isEmpty);
    expect(context.knowledge, isEmpty);
    expect(context.products, isEmpty);
    expect(context.assets, isEmpty);
    expect(context.services, isEmpty);
    expect(context.websites, isEmpty);
    expect(context.social, isEmpty);
    expect(context.analytics, isEmpty);
  });

  test('build() performs no LLM calls: it is a synchronous, pure function '
      'from documents straight to CompanyContext, with no Future involved', () {
    const builder = CompanyContextBuilder();

    // build() returns a CompanyContext directly, not a Future<...>: it
    // is impossible for it to await a ModelProvider call, since doing
    // so would force it to return a Future.
    final CompanyContext context = builder.build(const []);

    expect(context, isA<CompanyContext>());
  });
}
