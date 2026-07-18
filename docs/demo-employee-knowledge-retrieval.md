# Demo: Employee Knowledge Retrieval

Status: Demo / reference — proven by
`test/hq/employee_knowledge_retrieval_end_to_end_test.dart`, not a
standalone CLI command.

## Scenario

A user asks the **CEO** Employee "How does our commission engine work?".
The CEO consults its own Knowledge Base through the `knowledge_search` Tool
before answering, then uses the retrieved document to compose its final
answer.

```
User
  │  "How does our commission engine work?"
  ▼
CEO Employee
  │  model chooses to call the knowledge_search Tool
  ▼
ToolCall(knowledge_search, {query: "commission engine"})
  │  Runtime -> ToolInvoker -> KnowledgeSearchTool.execute()
  ▼
KnowledgeSearchTool
  │  deterministic title/filename/keyword match over the CEO's own
  │  KnowledgeDefinitions
  ▼
Matching Markdown document(s)  ──────────────► ToolOutput
  │
  ▼
CEO's Conversation (ToolMessage appended by Runtime's existing tool loop)
  │
  ▼
CEO Employee (second turn)
  │  uses the ToolOutput to produce its final answer
  ▼
Final Answer  ──────────────► returned to the user
```

## Retrieval is deterministic, not semantic

`KnowledgeSearchTool` matches a query against three things per document,
case-insensitively:

- **title** — the first Markdown heading (e.g. `# Commission Engine`).
- **filename** (`id`) — the document's filename without extension (e.g.
  `commission-engine.md` → `commission-engine`).
- **content** — a plain substring/keyword match over the whole document.

There is no embeddings, no vector search, no RAG pipeline, no caching, and
no indexing — exactly the "just deterministic retrieval" this task calls
for. If more than one document matches, all matches are returned, joined
with a `---` separator; if none match, the tool still succeeds, returning a
"No matching knowledge found" message rather than failing.

## Knowledge is scoped per Employee

`KnowledgeSearchTool` is constructed with one specific Employee's
`List<KnowledgeDefinition>` (the same model `KnowledgeRepository` already
produces during HQ boot) and only ever searches that list — it has no way
to reach any other Employee's documents, by construction. In this demo, the
CEO's real, `HQBootstrap`-produced `EmployeeRuntime` is resolved once, and
`KnowledgeSearchTool` is built directly from `ceo.knowledge` before `HQ`
itself is constructed:

```dart
final bootResult = await bootstrap.boot(source);
final ceo = bootResult.employees.single;

final toolRegistry = ToolRegistry(
  tools: {'knowledge_search': KnowledgeSearchTool(knowledge: ceo.knowledge)},
  definitions: const {
    'knowledge_search': ToolDefinition(
      id: 'knowledge_search',
      description: "Search this Employee's own knowledge base.",
    ),
  },
);

final hq = HQ(
  modelProvider: modelProvider,
  bootstrap: bootstrap,
  source: source,
  toolRegistry: toolRegistry,
);
```

Unlike `DelegateEmployeeTool` (HQ-004), `KnowledgeSearchTool` needs no
reference back to `HQ` itself, so no lazy-provider trick is required here —
only the target Employee's already-loaded knowledge list, which is
available before `HQ` is ever constructed.

## What is real vs. simulated

Only the model's responses are faked, via a small scripted `ModelProvider`
returning, in order: (1) the CEO's first turn → a
`ToolCall(knowledge_search, ...)`, and (2) the CEO's second turn → the
final answer. This is unavoidable and consistent with every other test in
this codebase: `.ai/RULES.md` forbids connecting to any external API or
consuming OpenAI/Claude/Gemini tokens.

Everything downstream of a `ModelResponse` is the real, unmodified
production pipeline:

- Tool-call detection and the tool-execution loop: `Runtime.run()`
  (unchanged).
- Tool dispatch: `ToolInvoker.invoke()` (unchanged).
- The retrieval itself: `KnowledgeSearchTool.execute()` (new, this task).
- Recording what happened: the `ToolMessage` appended to the CEO's
  Conversation by Runtime's existing tool loop (pre-existing, unchanged).

## Guarantees demonstrated

- Exactly 2 model turns (CEO → CEO); no recursion, no retries, no parallel
  execution.
- The retrieved `ToolOutput` contains only the matching document(s) — an
  unrelated document in the same Knowledge Base (`onboarding.md`) is never
  included.
- Read-only: the tool never writes to or modifies any document.
