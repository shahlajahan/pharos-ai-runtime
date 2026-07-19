# Demo: Employee Conversation Memory Search

Status: Demo / reference — proven by
`test/hq/employee_conversation_memory_search_end_to_end_test.dart`, not a
standalone CLI command.

## Scenario

The user tells the **CEO** Employee "My preferred database is PostgreSQL.
Remember that." in one `hq.execute()` call. Later, in a separate
`hq.execute()` call that shares the same `ConversationMemory`, the user
asks "What is my preferred database?". The CEO consults this
conversation's own memory through the `memory_search` Tool before
answering, then uses the retrieved entry to compose its final answer.

```
User                                            User
  │  "My preferred database is PostgreSQL.        │  "What is my preferred
  │   Remember that."                              │   database?"
  ▼                                                 ▼
CEO Employee (call 1)                           CEO Employee (call 2)
  │  plain-text acknowledgement,                   │  model chooses to call
  │  no tool call                                  │  the memory_search Tool
  ▼                                                 ▼
ConversationMemory                              ToolCall(memory_search,
  │  UserMessage + AssistantMessage                 {query: "PostgreSQL"})
  │  recorded automatically by                      │  Runtime -> ToolInvoker
  │  Runtime.run()                                  │  -> MemorySearchTool
  │                                                  ▼
  └──────────────────────────────────────►  Matching MemoryEntry ──► ToolOutput
                                                      │
                                                      ▼
                                             CEO's Conversation (ToolMessage
                                             appended by Runtime's existing
                                             tool loop)
                                                      │
                                                      ▼
                                             CEO Employee (second turn)
                                                      │  uses the ToolOutput to
                                                      │  produce its final answer
                                                      ▼
                                             Final Answer ──► returned to the user
```

## Retrieval is deterministic, not semantic

`MemorySearchTool` matches a query against one thing per `MemoryEntry`,
case-insensitively:

- **content** — a plain substring/keyword match over the entry's text.

There is no embeddings, no vector search, no ranking, and no
summarization — exactly the "just deterministic retrieval" this task
calls for. If more than one entry matches, all matches are returned, in
chronological order, joined with a `---` separator; if none match, the
tool still succeeds, returning a "No matching memory found" message
rather than failing. The tool never writes to or modifies the
`MemoryStore`.

## Memory is scoped per Conversation

`MemorySearchTool` is constructed with one specific `ConversationMemory`'s
`MemoryStore` (reusing the exact `MemoryStore` contract `ConversationMemory`
already uses to persist entries) and only ever searches that store — it
has no way to reach any other conversation's entries, by construction.
Since `HQContext` creates a fresh `ConversationMemory` per `hq.execute()`
call by default, this demo passes one explicit, shared `ConversationMemory`
into both calls so the second call's `memory_search` can find what the
first call recorded:

```dart
final memory = ConversationMemory();

final toolRegistry = ToolRegistry(
  tools: {'memory_search': MemorySearchTool(store: memory.store)},
  definitions: const {
    'memory_search': ToolDefinition(
      id: 'memory_search',
      description: "Search this conversation's own memory.",
    ),
  },
);

final hq = HQ(
  modelProvider: modelProvider,
  bootstrap: bootstrap,
  source: source,
  toolRegistry: toolRegistry,
);

await hq.execute(employee: 'ceo', goal: '...', memory: memory);
await hq.execute(employee: 'ceo', goal: '...', memory: memory);
```

Every `UserMessage`, `AssistantMessage`, and `ToolMessage` produced across
both calls is recorded into `memory` automatically by `Runtime.run()` —
this demo never calls `memory.record()` itself.

## What is real vs. simulated

Only the model's responses are faked, via a small scripted `ModelProvider`
returning, in order: (1) the first call's only turn → a plain-text
acknowledgement, (2) the second call's first turn → a
`ToolCall(memory_search, ...)`, and (3) the second call's second turn →
the final answer. This is unavoidable and consistent with every other test
in this codebase: `.ai/RULES.md` forbids connecting to any external API or
consuming OpenAI/Claude/Gemini tokens.

Everything downstream of a `ModelResponse` is the real, unmodified
production pipeline:

- Automatic recording: `Runtime.run()`'s existing `ConversationMemory`
  wiring (unchanged).
- Tool-call detection and the tool-execution loop: `Runtime.run()`
  (unchanged).
- Tool dispatch: `ToolInvoker.invoke()` (unchanged).
- The retrieval itself: `MemorySearchTool.execute()` (new, this task).
- Recording what happened: the `ToolMessage` appended to the CEO's
  Conversation by Runtime's existing tool loop (pre-existing, unchanged).

## Guarantees demonstrated

- Exactly 3 model turns total across both calls (1 + 2); no recursion, no
  retries, no parallel execution.
- The retrieved `ToolOutput` contains the matching entry recorded during
  the first, separate `hq.execute()` call — proving memory persists across
  calls only through the explicitly shared `ConversationMemory`, never
  through the model `Conversation` itself.
- Read-only: the tool never writes to or modifies the `MemoryStore`.
