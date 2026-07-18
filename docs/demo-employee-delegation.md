# Demo: End-to-End Employee Delegation

Status: Demo / reference — proven by
`test/hq/employee_delegation_end_to_end_test.dart`, not a standalone CLI
command.

## Scenario

A user asks the **CEO** Employee to prepare a LinkedIn announcement. The CEO
recognizes this is a marketing task and delegates it to the **Marketing**
Employee through the `delegate_employee` Tool, then uses Marketing's draft to
produce its final answer.

```
User
  │  "Prepare a LinkedIn announcement for our new Flutter package."
  ▼
CEO Employee
  │  model chooses to call the delegate_employee Tool
  ▼
ToolCall(delegate_employee, {employee: "marketing", goal: "..."})
  │  Runtime -> ToolInvoker -> DelegateEmployeeTool.execute()
  ▼
DelegateEmployeeTool
  │  HQ.invoke(employee: "marketing", goal: "...")
  ▼
Marketing Employee
  │  drafts the announcement (its own, independent Runtime.run())
  ▼
Result  ──────────────► ToolOutput  ──────────────► CEO's Conversation
  │
  ▼
CEO Employee (second turn)
  │  uses the ToolOutput to produce its final answer
  ▼
Final Answer  ──────────────► returned to the user
```

## The two Employees

**CEO** (`employees/ceo/employee.md` + `employees/ceo/prompts/delegation.md`)
— its prompt explicitly describes *when* delegation is appropriate: for
marketing-shaped requests (announcements, social posts, campaign copy), call
`delegate_employee` targeting `"marketing"` instead of writing the copy
itself, then use the returned draft to compose the final answer.

**Marketing** (`employees/marketing/employee.md` +
`employees/marketing/prompts/marketing.md`) — its prompt specializes *only*
in marketing tasks; it has no knowledge of delegation and never calls
`delegate_employee` itself.

The end-to-end test creates both as real, temporary HQ directories (valid
`employee.md`, `knowledge/`, and `prompts/` per the HQ structure required by
`HQValidator`/`EmployeeFactory`) and boots them through the real
`HQBootstrap` pipeline — nothing about Employee resolution or loading is
faked.

## What is real vs. simulated

Only one thing is faked: **the model's responses**, via a small scripted
`ModelProvider` that returns, in order:

1. CEO's first turn → a `ToolCall(delegate_employee, ...)` (the "model
   chooses the tool").
2. Marketing's only turn → a plain-text draft, no further tool calls.
3. CEO's second turn → the final answer.

This is unavoidable and consistent with every other test in this codebase:
`.ai/RULES.md` forbids connecting to any external API or consuming
OpenAI/Claude/Gemini tokens, so no test in this repository ever calls a real
model.

Everything downstream of a `ModelResponse` is the real, unmodified
production pipeline — no orchestration code exists outside it:

- Tool-call detection and the tool-execution loop: `Runtime.run()`
  (unchanged).
- Tool dispatch: `ToolInvoker.invoke()` (unchanged).
- The delegation itself: `DelegateEmployeeTool.execute()` (HQ-004).
- Delegated execution: `HQ.invoke()` → a brand-new `Runtime.run()` call for
  Marketing (HQ-003).
- Recording what happened: `AssistantMessage`/`ToolMessage` appended to the
  CEO's Conversation by Runtime's existing tool loop (pre-existing,
  unchanged).

## Wiring `DelegateEmployeeTool` into an `HQ`

`DelegateEmployeeTool` needs a reference to the very `HQ` whose
`ToolRegistry` it lives in — a genuine circular construction dependency,
since the `ToolRegistry` must exist before `HQ` can be constructed. This is
solved with a lazy provider and Dart's `late` variables:

```dart
late final HQ hq;

final toolRegistry = ToolRegistry(
  tools: {'delegate_employee': DelegateEmployeeTool(hq: () => hq)},
  definitions: const {
    'delegate_employee': ToolDefinition(
      id: 'delegate_employee',
      description: 'Delegate a task to another Employee.',
    ),
  },
);

hq = HQ(
  modelProvider: modelProvider,
  bootstrap: bootstrap,
  source: source,
  toolRegistry: toolRegistry,
);
```

The closure `() => hq` captures the *variable*, not its value — by the time
`DelegateEmployeeTool.execute()` actually calls it, `hq` has long since been
assigned. This wiring is intentionally local to this demo/test; the tool is
not wired into `bin/pharos.dart`'s default `ToolRegistry`.

## Guarantees demonstrated

- Exactly one delegation occurs (3 model turns total: CEO → Marketing →
  CEO); no recursion, no employee chains, no parallel execution, no
  retries.
- If the delegated Employee's own tool-calling loop tried to call
  `delegate_employee` again, it would be rejected as nested delegation
  (proven separately in `test/tooling/delegate_employee_tool_test.dart`).
