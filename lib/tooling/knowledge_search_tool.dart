import 'dart:convert';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';

/// Deterministic, read-only search over one Employee's own Knowledge Base
/// (the `List<KnowledgeDefinition>` produced by `KnowledgeRepository`).
///
/// Arguments: `{"query": "..."}`.
///
/// Matches are found by simple, deterministic comparison against each
/// document's title, filename (id), and content — no embeddings, no vector
/// search, no RAG pipeline, no caching, no indexing. A tool instance only
/// ever sees the knowledge it was constructed with, so it never searches
/// another Employee's documents.
class KnowledgeSearchTool extends Tool {
  KnowledgeSearchTool({required List<KnowledgeDefinition> knowledge})
    : _knowledge = knowledge;

  final List<KnowledgeDefinition> _knowledge;

  @override
  String get id => 'knowledge_search';

  @override
  Future<Result> execute(ToolContext context) async {
    final dynamic decoded;

    try {
      decoded = jsonDecode(context.arguments);
    } on FormatException {
      return Result.failure(
        'Invalid "knowledge_search" arguments: not valid JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return Result.failure(
        'Invalid "knowledge_search" arguments: expected a JSON object.',
      );
    }

    final query = decoded['query'];

    if (query is! String || query.isEmpty) {
      return Result.failure(
        'Invalid "knowledge_search" arguments: "query" is required.',
      );
    }

    final normalizedQuery = query.toLowerCase();

    final matches = _knowledge.where((document) {
      return document.title.toLowerCase().contains(normalizedQuery) ||
          document.id.toLowerCase().contains(normalizedQuery) ||
          document.content.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (matches.isEmpty) {
      return Result.success('No matching knowledge found for "$query".');
    }

    final content = matches
        .map((document) => document.content)
        .join('\n\n---\n\n');

    return Result.success(content);
  }
}
