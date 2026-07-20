import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/company_document.dart';

/// Transforms loaded CompanyDocuments into one CompanyContext. Only
/// context assembly: no LLM calls, no business decisions, no prompt
/// generation.
class CompanyContextBuilder {
  const CompanyContextBuilder();

  CompanyContext build(List<CompanyDocument> documents) {
    return CompanyContext(
      company: _section(documents, 'company'),
      knowledge: _section(documents, 'knowledge'),
      products: _section(documents, 'products'),
      assets: _section(documents, 'assets'),
      services: _section(documents, 'services'),
      websites: _section(documents, 'websites'),
      social: _section(documents, 'social'),
      analytics: _section(documents, 'analytics'),
    );
  }

  List<String> _section(List<CompanyDocument> documents, String category) {
    return documents
        .where((document) => document.category == category)
        .map(_normalize)
        .toList();
  }

  /// Strips markdown heading markers and surrounding whitespace — never
  /// interprets or summarizes the content itself.
  String _normalize(CompanyDocument document) {
    final content = document.content
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .trim();

    return '${document.name}: $content';
  }
}
