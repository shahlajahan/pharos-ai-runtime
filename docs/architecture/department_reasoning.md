# Department Reasoning Layer — From Company Summary to Company Plan

## Why

The previous flow (`CompanyContext` -> `CompanySnapshot` -> LLM ->
Executive Summary) produced one generic company-wide summary. A CEO does
not need another summary — a CEO needs today's execution plan, broken
down by the people actually responsible for it. This task replaces
document-centric reasoning with **department-centric** reasoning: the
Runtime now understands the company per department before the LLM ever
writes anything.

## Core Types

```
lib/company/department.dart
lib/company/department_context.dart
lib/company/department_context_builder.dart
lib/company/department_snapshot.dart
lib/prompts/department_prompt_builder.dart
```

### `Department`

An enum of the six built-in departments: Executive, Engineering,
Marketing, Sales, Operations, Finance. Additional departments can be
added here without touching `DepartmentContextBuilder`,
`DepartmentPromptBuilder`, or the Runtime — every consumer iterates over
`Department.values`.

### `DepartmentContext`

The subset of `CompanyContext` relevant to one department. Deterministic
and immutable: built once per department, never mutated, never calls the
LLM. Carries a `relevantCategories` set naming exactly which HQ
categories that department reasons over, so a category the department
has no mandate over is never treated as "missing" either.

### `DepartmentContextBuilder`

```dart
const builder = DepartmentContextBuilder();
final contexts = builder.buildAll(companyContext);
```

Builds one `DepartmentContext` per department from a single
`CompanyContext`. Only extraction — no prompting, no reasoning, no
recommendations:

- `Company` is always included, unfiltered, for every department.
- `Knowledge` is filtered per department by a fixed keyword vocabulary
  (Executive is the one exception — it sees every document, since its
  job is to spot cross-department blockers).
- `Products`, `Assets`, `Services`, `Websites`, `Social`, and
  `Analytics` are included only for departments with an actual mandate
  over them (for example Marketing sees `Websites`/`Social`; Finance and
  Operations do not).

### `DepartmentSnapshot`

```dart
final snapshot = DepartmentSnapshot.fromContext(departmentContext);
```

Deduplicates each category, and identifies:

- `knownData` — relevant categories with at least one fact.
- `missingData` — relevant categories with nothing, plus this
  department's fixed set of unconnected data sources (for example
  Marketing always lists `GA4`, `Search Console`).
- `blockedItems` — one deterministic statement per missing entry.
- `evidence` — one `Evidence(category, source, confidence)` record per
  known fact, tracing it back to its HQ category and source document, so
  future explainability features can show why a recommendation was made.

### `DepartmentPromptBuilder`

```dart
const builder = DepartmentPromptBuilder();
final prompt = builder.buildReport(snapshots: snapshots, currentDate: DateTime.now());
```

`build()` produces one grounded prompt section per department. `buildReport()`
composes every department's section into the single request `DailyAgent`
sends the LLM, in a fixed department order, instructing it to write
exactly one "Today's `<Department>` Priorities" heading per department.

## The Daily Agent's Flow

```
HQ
  |
  v
Company Context
  |
  v
Department Context Builder
  |
  v
Department Contexts -> Department Snapshots
  |
  v
Department Prompt Builder
  |
  v
LLM
  |
  v
Today's Company Plan
```

## LLM Responsibility

The LLM writes only each department's "Today's `<Department>` Priorities"
section, grounded exclusively in that department's `DepartmentSnapshot`.
It never decides what is known, missing, or blocked — those are
Runtime responsibilities. `Blocked Items`, `Missing Data`, and
`Recommended Next Connections` are rendered by `DailyAgent` directly from
the already-computed snapshots, the same way `Data Sources Used` was
Runtime-rendered in the previous task: identifying gaps is inference the
LLM must never perform.

## Report Structure

```
══════════════════════════════
PHAROS TODAY
══════════════════════════════

Today's Executive Priorities
Today's Engineering Priorities
Today's Marketing Priorities
Today's Sales Priorities
Today's Operations Priorities
Today's Finance Priorities

Blocked Items
Missing Data
Recommended Next Connections
```

The six priority sections come from the LLM, one per department. The
final three sections are appended by the Runtime, deterministically,
from the union of every department's `missingData` / `blockedItems`.

## What This Task Does Not Do

- No CRM, Analytics, Gmail, GitHub, or Calendar connector is
  implemented — each department's fixed connector-gap list in
  `DepartmentSnapshot` names exactly the sources it does not have yet.
- The Workflow Engine, Tool Registry, and Provider Layer are untouched.
- No business logic lives inside prompts — `DepartmentContextBuilder`
  and `DepartmentSnapshot` decide what is known, missing, and blocked;
  `DepartmentPromptBuilder` and `DailyAgent` only render already-computed
  data.
- The previous `CompanySnapshot` / `CompanySnapshotBuilder` /
  `DailyPromptBuilder` types are left in place (still independently
  tested) but are no longer used by `DailyAgent`, which now reasons per
  department instead of per document.
