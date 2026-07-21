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

## Planner (`lib/workflow/planner/`)

HQ-100.3 answers "how should the company do it?" — planning only, still
no execution:

```
Decision
  |
  v
WorkflowMatcher
  |
  v
WorkflowDefinition
  |
  v
WorkflowInstance
  |
  v
Execution Plan (WorkflowPlan)
```

- **`WorkflowInstance`** — one *planned execution* of a
  `WorkflowDefinition`: `id`, `definitionId` (traces back to the
  template), `status`, `context`, `steps`, `createdAt`, `plannedAt`.
  Every planning request creates a new one.
- **`WorkflowPlan`** — the deterministic execution order: `orderedSteps`
  (a full topological order), `parallelGroups` (steps sharing no
  dependency on each other, grouped by execution stage — matching the
  roadmap's Launch Campaign example exactly: `[Analyze Market, Analyze
  Budget]`, `[Design Campaign]`, `[Generate Images, Generate Videos]`,
  `[Publish]`, `[Measure]`), `blockedSteps`, `warnings`,
  `estimatedStepCount`. No runtime state.
- **`PlanningResult`** — the outcome of one `plan()` call: `success`,
  `workflow` (a `WorkflowInstance?`), `plan` (a `WorkflowPlan?`),
  `errors`, `warnings`. `workflow`/`plan` stay `null` whenever
  `success` is `false` — an invalid workflow never produces an
  instance.
- **`WorkflowPlanner`** (`lib/workflow/planner/workflow_planner.dart`)
  — `PlanningResult plan(Decision decision, WorkflowContext context)`.
  Contract only.
- **`DefaultWorkflowPlanner`** — the implementation. Selects a
  `WorkflowDefinition` via `WorkflowMatcher`, then validates its steps
  before ever building an instance: duplicate ids, missing
  dependencies, circular dependencies, unreachable (fully disconnected)
  steps, and empty workflows all reject the plan (`success: false`, no
  instance). Only once validation passes does it compute the
  `WorkflowPlan` via a Kahn-style level ordering (each pass collects
  every step whose dependencies are already satisfied, so
  independent steps land in the same parallel group) and build the
  `WorkflowInstance`. Knows workflows, dependencies, and planning only
  — never AI, agents, tools, HTTP, LLMs, APIs, finance, or CRM.

### Note on the two `WorkflowPlanner`s

HQ-100.1 already introduced a `WorkflowPlanner` contract at
`lib/workflow/contracts/workflow_planner.dart`
(`Workflow plan(Decision decision, WorkflowContext context)` — always
succeeds, no validation, no failure mode). This milestone's
`lib/workflow/planner/workflow_planner.dart` is the same abstraction
evolved with a real implementation: planning can now fail, so the
return type became `PlanningResult` (which carries the `WorkflowInstance`
only on success) instead of a bare `Workflow`. The HQ-100.1 contract is
left in place, untouched and unused, rather than deleted or modified —
`lib/workflow/planner/workflow_planner.dart` is the one a real
`WorkflowPlanner` implementation should depend on going forward.

## Simulation (`lib/workflow/simulation/`)

HQ-100.4 lets the Executive understand not only *what* should happen,
but *how* it would happen — still without anything executing:

```
Company Decision
  |
  v
Workflow Planner
  |
  v
Workflow Instance
  |
  v
Workflow Simulator
  |
  v
Execution Preview
  |
  v
Executive Brief
```

- **`WorkflowSimulation`** — the complete execution preview:
  `workflowId`, `executionGroups`, `estimatedStepCount`,
  `estimatedParallelGroups`, `estimatedDuration` (sum of each group's
  *slowest* step — groups run in sequence, but steps inside one group
  run in parallel), `warnings`, `blockedSteps`.
- **`SimulationResult`** — the outcome of one `simulate()` call:
  `success`, `simulation` (a `WorkflowSimulation?`), `errors`,
  `warnings`. Mirrors `PlanningResult`'s shape, but `success` stays
  `true` even when issues are found (they become `warnings` /
  `blockedSteps`) — by the time a `WorkflowInstance` reaches the
  simulator it already passed the Planner's hard validation, so the
  simulator's own checks are a defensive second pass, not a gate.
  `success` is only `false` when nothing can be simulated at all (no
  steps).
- **`WorkflowSimulator`** — walks the dependency graph independently of
  the Planner (re-deriving groups from the instance's own steps, since
  a step already marked `failed`/`skipped` — or depending on one — is
  blocked for *this* preview even though the Planner never rejected the
  original definition), estimates duration from each step's
  `metadata['estimatedDurationSeconds']` (falling back to a 1-minute
  default), and never mutates the `WorkflowInstance` it receives. Knows
  workflows, dependencies, and execution order only — never AI, agents,
  tools, HTTP, APIs, CRM, or finance.

### Executive Integration

`DailyAgent` now plans and simulates a Workflow for each of the
Executive's top company decisions (at most 3) against a single
built-in `launch_campaign` `WorkflowDefinition` — the roadmap's own
Launch Campaign example, matched to `DecisionType.launch`, which is
exactly the type the Decision Engine's "Prepare launch campaign" rule
already produces. A decision with no matching workflow, or whose plan
fails validation, simply contributes no preview; that is expected, not
an error. The printed Executive Brief gains a Runtime-rendered
"Execution Preview" section (`Workflow: launch_campaign`, `Status:
Ready`/`Blocked`, then each execution group with a step title per
line) — never sent to the LLM, since deciding execution order is
exactly the kind of inference the LLM must never perform. No other
built-in workflow is wired in yet; see the Registry section above for
why.

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
