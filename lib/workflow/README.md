# Workflow Domain Model

HQ-100.1 introduces the foundational domain model for workflow
execution — the first milestone of Roadmap Phase 2 ("Company
Workflows"). It converts company Decisions into structured, executable
Workflows. This milestone is **domain objects and contracts only**:
no execution, no agents, no external integrations.

```
Decision
  |
  v
Workflow Planner
  |
  v
Workflow
  |
  v
Workflow Steps
  |
  v
Execution (future)
```

## Models (`lib/workflow/models/`)

- **`Workflow`** — one complete business process: `id`, `type`,
  `title`, `description`, `priority`, `status`, `context`, `steps`,
  `createdAt`, `updatedAt`. Immutable value object — no execution
  logic, no API knowledge.
- **`WorkflowStep`** — one unit of work: `id`, `title`, `description`,
  `status`, `dependsOn` (the ids of steps that must complete first),
  `metadata`. No execution logic.
- **`WorkflowContext`** — everything a Workflow needs before it can
  execute: `company`, `market`, and `finance` context data. No
  workflow should ever execute without all three. Structural data
  only — no AI, no API calls. Concrete Company/Market/Financial
  context providers are future roadmap work (Phase 3).
- **`WorkflowResult`** — an execution placeholder: `success`,
  `completedSteps`, `failedSteps`, `duration`, `outputs`. No
  implementation exists yet.
- **`WorkflowType`**, **`WorkflowPriority`**, **`WorkflowStatus`**,
  **`WorkflowStepStatus`** — fixed enums. `WorkflowStatus`
  deliberately has no "draft": a Workflow is either `planned` or
  executable.

## Contracts (`lib/workflow/contracts/`)

- **`WorkflowPlanner`** — `Workflow plan(Decision decision,
  WorkflowContext context)`. Contract only, no implementation. Turns
  one company `Decision` (from `lib/decision/decision.dart`, produced
  by the Decision Engine) into a `Workflow`. The Decision Engine
  determines *what* the company should do; a `WorkflowPlanner`
  determines *how*.

## Registry (`lib/workflow/registry/`)

HQ-100.2 introduces the catalog a `WorkflowPlanner` will consult
instead of hardcoding `if (decision == "launch") ...` logic:

```
Decision
  |
  v
Workflow Planner
  |
  v
Workflow Registry
  |
  v
Workflow Definition
  |
  v
Workflow Object
```

- **`WorkflowDefinition`** — a reusable workflow *template*, not a
  running instance: `id`, `type`, `title`, `description`,
  `supportedDecisionTypes` (which `DecisionType`s it can be matched
  against), `defaultPriority`, `steps`, `metadata`. Immutable, no
  runtime state, no execution logic.
- **`WorkflowRegistry`** — stores `WorkflowDefinition`s: `register()`
  (rejects a duplicate id rather than silently overwriting it),
  `unregister()`, `findByType()`, `findByDecision()` (the first
  registered definition, in registration order, whose
  `supportedDecisionTypes` includes the Decision's type), `all()`.
  Contains definitions only — no execution, no knowledge of agents,
  tools, AI, or external APIs.
- **`WorkflowMatcher`** — the thin, dedicated component a
  `WorkflowPlanner` actually depends on: `match(Decision)` delegates
  to `WorkflowRegistry.findByDecision()`. It never creates a Workflow
  itself, only selects the correct definition; kept as its own class
  (rather than folded into the registry) so future matching policy
  (for example department- or title-aware matching) can change
  without touching the registry's storage API.

This milestone does not wire any built-in workflow definitions
(`launch_campaign`, `partner_outreach`, `product_release`,
`customer_support`, `engineering_task`, `finance_review`,
`operations_review`) into a bootstrap/startup path — no such path
exists yet. The registry's test suite demonstrates registering all
seven using the public API described above; a future task can decide
where the canonical built-in definitions actually live.

## Design Rules

Every model here is immutable, contains no side effects, no service
references, no HTTP, no LLM, and no Tool invocation. The shape is
built to support sequential workflows, parallel workflows, retries,
rollback, conditional branches, and nested workflows later without
breaking this API — none of that exists yet.

## Note on the sibling `lib/workflow/*.dart` files

The flat files directly under `lib/workflow/` (`workflow.dart`,
`workflow_context.dart`, `workflow_result.dart`,
`workflow_step_result.dart`, `default_workflow.dart`) are a pre-existing,
unrelated abstraction from the original Runtime execution pipeline —
`abstract class Workflow { execute(ExecutionDecision) }`, still actively
used by `lib/runtime/`. They predate the Company Brain / Decision
Engine work and are untouched by this milestone. The two `Workflow`
names coexist in different files under different import paths
(`package:pharos_ai_runtime/workflow/workflow.dart` vs
`package:pharos_ai_runtime/workflow/models/workflow.dart`); importers
of both in the same file will need an import prefix to disambiguate.
