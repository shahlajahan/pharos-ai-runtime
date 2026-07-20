# Priority & Executive Aggregation Engine

## Why

The Decision Engine ranks decisions *within* one department. Nothing
combined that work across departments — the Executive would have had to
look at Marketing's, Engineering's, and Finance's decisions
independently, see "Connect GA4" twice if two departments both raised
it, and see raw signal names like `reachable`/`lastDeploy` instead of a
dashboard. This layer fixes that: the Executive receives one ranked,
deduplicated, deterministic view of the highest-value work across the
whole company.

## Core Types

```
lib/priorities/priority_score.dart
lib/priorities/decision_ranker.dart
lib/priorities/priority_engine.dart
lib/priorities/department_summary.dart
lib/priorities/executive_summary.dart
lib/priorities/executive_aggregator.dart
```

### `PriorityScore`

`value = Impact x Urgency x Confidence x EvidenceCompleteness` — the
exact formula from the task, built from a `Decision`'s existing
`DecisionScore` and `confidence`. `percentage` renders it as the
whole-number scores the task's examples use (96, 91, 84, ...).

### `DecisionRanker`

Deterministically ranks a `List<Decision>` by `PriorityScore`, highest
first, id as tiebreaker. `rank()` only ever considers decisions that
are *not* `blocked`; `rankBlocked()` only considers ones that are. This
is how "the Runtime understands dependencies": a blocked decision can
never be promoted into the ranked, actionable list no matter how high
its score would otherwise be — the same way the Decision Engine's
`Campaign Optimization` blocker (which only exists *because* analytics
is missing) never appears as a normal recommendation.

### `PriorityEngine`

Wraps `DecisionRanker` with a department's top-N cut (`topCount`,
default 3): `topDecisions()` and `blockedDecisions()`.

### `DepartmentSummary`

One department's health: `decisionCount`, `blockedCount`,
`observability` (from `OperationalSnapshot.observabilityScore`),
`readiness` (the fraction of the department's tracked entities with
*every* signal known — stricter than the average `observability`
score), and a deterministic `health` — the average of observability and
readiness, discounted by how much of the department's work is
currently blocked. Also carries the department's `topDecisions` and
`blockedDecisions` (via `PriorityEngine`) and its raw
`missingOperationalData`, kept only so `ExecutiveAggregator` can
translate it — never rendered directly.

### `ExecutiveSummary` / `ExecutiveAggregator`

`ExecutiveAggregator.aggregate(departmentSummaries)` builds the
company-wide view:

- `companyHealth` — the average of every department's `health`.
- `topDecisions` / `blockedDecisions` — every department's top-N
  decisions, **merged by title** (a decision independently raised by
  two departments becomes one `MergedDecision` with `affects: [...]`
  naming both), then re-ranked and cut to the top 3 company-wide. The
  Executive never invents work — it only aggregates what departments
  already produced.
- `observabilityGaps` — every department's `missingOperationalData`
  signal names translated through `ExecutiveAggregator
  .observabilityCategories` into dashboard-level categories ("Analytics",
  "Social Metrics", "Deploy Status", "Repository Metrics", "Website
  Uptime", "Billing", "Revenue"). Several raw signals collapse into one
  category on purpose — connecting one analytics platform resolves
  several underlying signals at once, and the Executive should see that
  as a single gap, never as "Connect followers" / "Connect reachable" /
  "Connect lastDeploy" style recommendations.

## The Daily Agent's Flow

```
Load HQ
  |
  v
Company Documents
  |
  v
Fact Extraction
  |
  v
Knowledge Graph
  |
  v
Department Facts
  |
  v
Operational State
  |
  v
Decision Engine
  |
  v
Priority Engine (per department, via DepartmentSummary)
  |
  v
Executive Aggregator
  |
  v
LLM
  |
  v
Executive Brief
```

## Prompt Contract

The LLM receives exactly: Executive Summary (company health, decision
counts), Department Summaries, Health Scores, Top Decisions, Blocked
Decisions, and Observability Gaps. Nothing else — no `CompanyDocument`,
no raw markdown, no per-department decision list in isolation. It is
told explicitly not to calculate its own priority or health score, and
never to recommend action on a Blocked Decision. `Blocked Items` and
`Observability Gaps` in the final printed report are Runtime-rendered
directly from the `ExecutiveSummary`, replacing the previous per-signal
"Missing Operational Data" / "Recommended Next Connections" sections —
missing data is now a dashboard, not a recommendation.

## What This Task Does Not Do

- No filesystem, connectors, or LLM logic inside the priority/executive
  layer — every calculation reasons only over already-built
  `DepartmentSummary` objects.
- "Dependency Graph" understanding is implemented as: a blocked
  decision never displaces an available one in the ranked output,
  regardless of score. No separate graph data structure was introduced,
  since the Decision Engine's existing `blocked` flag already encodes
  exactly this relationship (a decision is blocked *because* its
  prerequisite evidence is missing).
- `KnowledgeGraph`, `DepartmentFacts`, `OperationalSnapshot`, and the
  Decision Engine itself are unchanged — this layer only sits between
  `DecisionEngine.generate()` and the prompt.
