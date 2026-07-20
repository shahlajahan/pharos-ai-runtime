# Operational State — Existence Is Not Readiness

## Why

`FactExtractor` and `KnowledgeGraph` tell the Runtime *what the company
has*: a Website fact exists, an Instagram fact exists, a GA4 fact
exists. Reasoning straight from that to a recommendation ("Website
exists -> review website performance") is wrong: existence is not
performance, a connected platform is not live data, and a fact alone
must never generate a recommendation. This layer distinguishes what the
company *owns* from what is *currently happening*, and gates
recommendations on the difference.

## Core Types

```
lib/operations/operational_state.dart
lib/operations/state_completeness.dart
lib/operations/operational_state_builder.dart
lib/operations/decision_gate.dart
lib/operations/operational_snapshot.dart
```

### `OperationalState`

One entity's readiness, expressed as a `Map<String, SignalState>` of
named signals (`SignalState` is `yes` / `no` / `unknown`). Always
includes `"exists"` (always `yes`, since a state is only ever built for
a fact the Knowledge Graph already has). Every other signal starts
`unknown` and only becomes `yes`/`no` when something else in the graph
— or the plain fact that this Runtime has no live connector at all yet
— settles it with certainty. Nothing is ever guessed.

### `OperationalStateBuilder`

```dart
const builder = OperationalStateBuilder();
final state = builder.build(fact, graph);
```

Deterministic, per-`FactType` rules, for example:

- `Website` -> `reachable` and `lastDeploy` stay unknown (no HTTP
  checker, no deploy log); `analyticsConnected` is `yes`/`no` based on
  whether the graph has any `AnalyticsPlatform` fact at all;
  `trafficMetricsAvailable` is always `no` — this Runtime has no live
  connector, so live traffic can never be available today.
- `SocialAccount` -> `followers`, `engagement`, `postingFrequency` stay
  unknown; `insightsConnected` is always `no`.
- `AnalyticsPlatform` -> `configured` is `yes` (the platform is known);
  `liveMetricsAvailable` is always `no`; `lastSync` stays unknown.
- `Repository` -> `ciStatus`, `deploymentStatus`,
  `documentationCoverage` stay unknown.
- `PaymentProvider` / `Subscription` -> `billingStatus` stays unknown;
  `revenueAvailable` is always `no`.
- Every other type (Product, BrandAsset, MediaAsset, ...) is
  **existence-only**: no additional readiness is expected of it, so its
  only signal is `exists`, and it is therefore always fully complete.

### `StateCompleteness`

```dart
const completeness = StateCompleteness();
completeness.calculate(state); // 0.0 - 1.0
```

The fraction of a state's signals that are not `unknown`. An
existence-only entity is always `1.0`. A `Website` with only `exists`
and `analyticsConnected`/`trafficMetricsAvailable` settled (and
`reachable`/`lastDeploy` unknown) sits below `1.0`.

### `DecisionGate`

```dart
const gate = DecisionGate();
final result = gate.evaluate(state); // DecisionGateResult
```

`allowed` is `true` only when **every** signal is known (no `unknown`
left) — an entity with even one unresolved readiness signal is
`blocked`, together with the list of `missingSignals` that block it.
`confidence` is derived from completeness: `>= 0.75` -> High,
`>= 0.4` -> Medium, otherwise Low. This is exactly why the four
"Allowed/Blocked Recommendation Rules" examples in the task work out
correctly: existence-only entities (Product, BrandAsset, MediaAsset)
are always allowed; Website/Instagram/GA4-style entities are blocked
today, since this Runtime has no connector that could ever resolve
their remaining unknown signals.

### `OperationalSnapshot`

```dart
final snapshot = OperationalSnapshot.build(
  departmentFacts: departmentFacts,
  graph: graph,
);
```

One department's operational picture: every relevant `OperationalState`
(from `DepartmentFacts.facts`), split into `allowed` and `blocked`
(with reasons), an aggregate `observabilityScore` (the mean
`StateCompleteness` across the department's states), and the
deduplicated `missingOperationalData` signal names behind every blocked
state.

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
Operational State Builder
  |
  v
Operational Snapshot  (Decision Gate applied per entity)
  |
  v
Department Prompt Builder
  |
  v
LLM
  |
  v
Executive Plan
```

## Prompt Contract

Per department, the prompt now contains exactly: Known Facts,
Operational State (every signal, per entity), Missing Operational Data,
"Allowed for action recommendations" / "Blocked (insufficient
evidence)" (with reasons and confidence), and a Decision Goal
instructing the LLM to recommend actions only for allowed entities, and
to recommend *improving observability* — never guessing — for blocked
ones. Never raw markdown, never a filesystem path, never a
`CompanyDocument`. `Blocked Items`, `Missing Operational Data`, and
`Recommended Next Connections` stay Runtime-rendered in the final
report, the same way earlier Runtime-owned sections were: identifying
gaps is inference the LLM must never perform.

## What This Task Does Not Do

- No HTTP reachability checks, no deploy logs, no social/analytics
  connectors, no databases — every signal beyond `exists` is either
  derived from facts already in the graph or permanently `no`/`unknown`
  because no live connector exists in this Runtime yet.
- Whether the LLM's actual recommendation text honors the Decision Gate
  is steered through the prompt's explicit allow/block lists, not
  verified deterministically afterward — the same limitation every
  prior task noted for LLM-authored prose the Runtime cannot re-parse
  without NLP.
- `KnowledgeGraph` and `DepartmentFacts` are unchanged; this layer only
  sits between them and the prompt.
