# Decision Engine — The Runtime Decides, the LLM Explains

## Why

Up to this point the LLM was handed grounded facts and operational
state and asked to *decide* what mattered today. That is backwards: the
Runtime has all the deterministic information needed to rank work, and
the LLM's judgment is exactly the kind of non-deterministic step this
codebase has avoided at every prior layer. This task moves prioritization
into the Runtime. The LLM becomes a communication layer — it explains
decisions the Runtime already made; it never makes them.

## Core Types

```
lib/decision/decision.dart
lib/decision/decision_type.dart
lib/decision/decision_priority.dart
lib/decision/decision_score.dart
lib/decision/decision_reason.dart
lib/decision/decision_rule.dart
lib/decision/decision_engine.dart
```

### `Decision`

A structured business object, not a sentence: `id`, `department`,
`title`, `type` (`DecisionType`), `priority` (`DecisionPriority`),
`score` (`DecisionScore`), `blocked`, `reasons` (`List<DecisionReason>`),
and `evidence` (`List<FactType>`). `confidence` is a convenience getter
over `score.evidenceCompleteness`. Every field is computed by the
Runtime; the LLM receives the finished object.

### `DecisionType`

The ten categories from the task: `launch`, `improve`, `connect`,
`fix`, `review`, `monitor`, `document`, `research`, `blocker`, `risk`.
`DecisionEngine.isActionable()` treats `launch`/`improve`/`connect`/`fix`
as priorities; every other non-blocked type renders as an informational
note. Not every type has a default rule producing it yet — the same
"defined but not always populated" pattern already used for `FactType`.

### `DecisionScore` / `DecisionPriority`

`DecisionScore.value` is `impact x urgency x evidenceCompleteness`
(each 0.0-1.0) — the exact formula from the task, with no AI involved.
`DecisionPriority.fromScore()` maps that value onto a fixed threshold
ladder: `>= 0.7` Critical, `>= 0.5` High, `>= 0.3` Medium, else Low.

### `DecisionReason`

One deterministic statement backing a decision (for example "Website
exists", "Analytics unavailable"). Always Runtime-generated, from a
`DecisionRule`'s own logic — never the LLM.

### `DecisionRule`

```dart
const DecisionRule(
  id: 'analytics.connect',
  department: Department.marketing,
  type: DecisionType.connect,
  title: 'Connect GA4',
  impact: 0.9,
  urgency: 0.9,
  appliesTo: _analyticsMissing,
  reasonsFor: _analyticsMissingReasons,
  evidenceFor: _analyticsMissingEvidence,
);
```

A rule is data: an `appliesTo` predicate over an `OperationalSnapshot`,
plus functions producing the resulting reasons and evidence. Rules are
configurable — `DecisionEngine` takes a `rules` list in its constructor,
defaulting to `DecisionEngine.defaultRules`, so new rules can be added
or swapped without touching the engine's ranking logic. Every default
rule only ever fires on a deterministically resolved signal (a known
`yes`/`no`, or a fact type's confirmed absence) — never on an `unknown`
one — which is why every default rule's `evidenceCompleteness` is `1.0`:
if the premise is uncertain, the rule simply does not fire yet.

### `DecisionEngine`

```dart
const engine = DecisionEngine();
final decisions = engine.generate(snapshot); // capped, ranked
```

For a department's `OperationalSnapshot`, evaluates every applicable
rule, scores each resulting `Decision`, then ranks and caps: at most 3
blockers, 3 actionable priorities, and 3 informational notes — 9
decisions total, never the "20 recommendations" the task explicitly
rules out. Ranking is by `score.value` descending, with `id` as a
deterministic tiebreaker, so the same input always produces the same
order.

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
Prioritized Decisions
  |
  v
LLM
  |
  v
Executive Brief
```

## Prompt Contract

Per department, the prompt now contains exactly Top Decisions (capped
priorities), Blockers, Informational Notes, and each decision's Evidence
and Decision Score (impact, urgency, confidence) — never a
`CompanyDocument`, never raw markdown, and the LLM is explicitly told
not to calculate its own priority or invent, reorder, or merge
decisions. `Blocked Items`, `Missing Operational Data`, and
`Recommended Next Connections` stay Runtime-rendered in the final
report; blocked items are now sourced directly from `Decision.blocked`,
so blocked work is guaranteed to never be rendered as a normal
recommendation.

## What This Task Does Not Do

- No filesystem, HTTP, or connector access inside the decision layer —
  every rule reasons only over the already-built `OperationalSnapshot`.
- Whether the LLM's prose actually avoids inventing extra decisions is
  steered through the prompt's explicit instructions, not verified
  deterministically afterward — the same limitation every prior task
  noted for LLM-authored text the Runtime cannot re-parse without NLP.
- `KnowledgeGraph`, `DepartmentFacts`, and the operational-state types
  from the prior task are unchanged, aside from `OperationalSnapshot`
  gaining a `missingFactTypes` pass-through (needed so a rule like
  "brand assets are entirely missing" can be expressed) — nothing about
  how those types are built was redesigned.
