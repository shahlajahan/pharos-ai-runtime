import 'dart:convert';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory_store.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';

/// Deterministic, read-only search over one Conversation's own
/// ConversationMemory (via its MemoryStore) — the conversational
/// counterpart to KnowledgeSearchTool.
///
/// Arguments: `{"query": "..."}`.
///
/// Matches are found by simple, deterministic, case-insensitive substring
/// comparison against each MemoryEntry's content — no embeddings, no
/// vector search, no ranking, no summarization. A tool instance only ever
/// searches the MemoryStore it was constructed with, so it never searches
/// another conversation's entries.
class MemorySearchTool extends Tool {
  MemorySearchTool({required MemoryStore store}) : _store = store;

  final MemoryStore _store;

  @override
  String get id => 'memory_search';

  @override
  Future<Result> execute(ToolContext context) async {
    final dynamic decoded;

    try {
      decoded = jsonDecode(context.arguments);
    } on FormatException {
      return Result.failure(
        'Invalid "memory_search" arguments: not valid JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return Result.failure(
        'Invalid "memory_search" arguments: expected a JSON object.',
      );
    }

    final query = decoded['query'];

    if (query is! String || query.isEmpty) {
      return Result.failure(
        'Invalid "memory_search" arguments: "query" is required.',
      );
    }

    final normalizedQuery = query.toLowerCase();

    final entries = await _store.readAll();

    final matches = entries.where((entry) {
      return entry.content.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (matches.isEmpty) {
      return Result.success('No matching memory found for "$query".');
    }

    final content = matches.map((entry) => entry.content).join('\n\n---\n\n');

    return Result.success(content);
  }
}
