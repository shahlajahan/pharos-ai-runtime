# Company Knowledge Graph — Facts, Not Documents

## Why

The Runtime previously reasoned over markdown-derived strings at every
layer: `CompanyContext`, `DepartmentContext`, and `DepartmentSnapshot`
all carried document prose (or thin wrappers around it) all the way to
the LLM. This task makes the Runtime stop reasoning over documents and
start reasoning over structured `CompanyFact` objects — the Runtime
should understand "Petsupo", not "products/petsupo/overview.md".

## Core Types

```
lib/knowledge/company_fact.dart
lib/knowledge/fact_type.dart
lib/knowledge/fact_extractor.dart
lib/knowledge/knowledge_graph.dart
lib/knowledge/knowledge_graph_builder.dart
lib/knowledge/department_fact_builder.dart
lib/company/department_facts.dart
```

### `CompanyFact`

An immutable, deterministic unit of company knowledge: `id`, `type`
(`FactType`), `name`, structured `attributes`, `sources` (which HQ
documents it came from), `extractionRule`, `confidence`, and `visibleTo`
(which departments it is relevant to). `attributes` is deliberately left
empty by every extraction rule today — HQ prose cannot be turned into
structured fields (market, status, platforms, ...) without NLP or
inference, both of which are out of scope, so a fact only ever carries
what can be established with certainty: its identity.

### `FactType`

The 19 built-in fact kinds from the task (`company`, `capability`,
`product`, `service`, `website`, `domain`, `brandAsset`, `mediaAsset`,
`socialAccount`, `analyticsPlatform`, `repository`, `infrastructure`,
`competitor`, `targetMarket`, `technology`, `subscription`,
`paymentProvider`, `workflow`, `policy`). New types are added here, the
same way `Department` is extended — every consumer (`FactExtractor`,
`KnowledgeGraph`, `DepartmentFactBuilder`) only ever switches on
`FactType`, never assumes the full set is exhaustive.

### `FactExtractor`

```dart
const extractor = FactExtractor();
final facts = extractor.extract(companyDocuments);
```

The only place HQ document content is ever read. Purely structural,
deterministic rules based on a document's HQ category and name — never
NLP, never an LLM call, never a summary, never an inference:

- `company` -> `Company`, visible to every department.
- `knowledge` -> `Capability`, visible to Executive plus whichever
  departments' fixed vocabulary the document's content matches (the same
  keyword approach used previously for department context extraction).
- `products` -> `Product`, visible to Executive, Marketing, Engineering,
  Sales.
- `services` -> `Service`, visible to Executive and Engineering.
- `websites` -> `Website` (plus a `Domain` fact too, if the document
  name looks like a domain), visible to Executive and Marketing.
- `social` -> `SocialAccount`, visible to Executive and Marketing.
- `analytics` -> `AnalyticsPlatform`, visible to Executive and Marketing.
- `assets` -> real HQ content lives in subfolders below `assets/`, not
  flat, so `FactExtractor` dispatches on the first path segment below
  `assets/` (via `CompanyDocument.path`, which the loader now preserves
  alongside the existing basename-only `name`):
  - `assets/websites` -> `Website` (+ `Domain` if the name looks like one)
  - `assets/domains` -> `Domain`
  - `assets/social` -> `SocialAccount`
  - `assets/analytics` -> `AnalyticsPlatform`
  - `assets/services` -> `Service`
  - `assets/brand` -> `BrandAsset`
  - `assets/media` -> `MediaAsset`
  - `assets/seo` -> `SEOAsset`
  - `assets/ads` -> `AdvertisingPlatform`
  - `assets/accounts` -> `Account`, visible to Executive and Finance
  - `assets/infrastructure` -> `Infrastructure`, visible to Executive,
    Engineering, and Operations
  - `assets/crm` -> `Account`, visible to Executive and Sales
  - `assets/finance` -> split by document name: `PaymentProvider` if it
    contains "payment", `Account` if it contains "account", otherwise
    `Subscription`
  - Any other subfolder, or a file directly under `assets/` with no
    subfolder, falls back to the original rule: `BrandAsset` if the name
    contains "brand", otherwise `MediaAsset`.
- Any other top-level category produces no fact — "if a fact cannot be
  extracted confidently, ignore it" applies to unrecognized categories
  too.

### `KnowledgeGraph`

```dart
final graph = KnowledgeGraph(facts: facts);
graph.products();
graph.factsByDepartment(Department.marketing);
```

Pure storage and querying — no prompting, no recommendations. Exposes
`products()`, `capabilities()`, `socialAccounts()`, `websites()`,
`competitors()`, `technologies()`, `marketingAssets()`,
`engineeringAssets()`, `factsByType()`, and `factsByDepartment()`.

### `KnowledgeGraphBuilder`

```dart
const builder = KnowledgeGraphBuilder();
final graph = builder.build(facts);
```

Merges facts that share the same `id` (for example the same product
mentioned by two different HQ documents) into one fact with combined
`sources`, unioned `visibleTo`, and the higher `confidence`.

### `DepartmentFacts` / `DepartmentFactBuilder`

```dart
const builder = DepartmentFactBuilder();
final departmentFacts = builder.buildAll(graph);
```

Replaces the markdown-era `DepartmentContext`/`DepartmentSnapshot`.
`DepartmentFactBuilder` holds a fixed map of which `FactType`s each
department has a mandate over (Executive keeps every type, to spot
cross-department blockers) and, per department, returns a
`DepartmentFacts` with only the facts visible to it, `knownTypes`
(relevant types with at least one fact), and `missingTypes` (relevant
types with none — never guessed, always reported).

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
Department Prompt Builder
  |
  v
LLM
  |
  v
Executive Plan
```

`DailyAgent` never inspects markdown directly — `FactExtractor` is the
only place `CompanyDocument.content` is read at all. Everything after
extraction (`KnowledgeGraph`, `DepartmentFacts`, the prompt) works
exclusively with `CompanyFact` objects.

## Prompt Rules

`DepartmentPromptBuilder` now renders `Facts:` (`FactType: name` per
known fact) and `Missing Facts:` per department — never a document
excerpt. The Reasoning Goal instructs the LLM to cite the `CompanyFact`
type(s) behind every recommendation as evidence, state a confidence
level, and never recommend anything without evidence. `Blocked Items`,
`Missing Facts`, and `Recommended Next Connections` are still rendered
by the Runtime directly from the `DepartmentFacts`, the same way they
were rendered from `DepartmentSnapshot` previously — identifying gaps is
inference the LLM must never perform.

## What This Task Does Not Do

- No NLP, embeddings, vector search, semantic retrieval, live
  connectors, or databases — extraction is purely structural.
- `CompanyFact.attributes` stays empty for every fact today; populating
  real structured fields (market, status, platforms, ...) would require
  inference this task explicitly forbids.
- Several built-in `FactType`s (`Repository`, `Competitor`,
  `TargetMarket`, `Technology`, `Workflow`, `Policy`) still have no HQ
  folder to extract from, so `FactExtractor` never produces them today —
  they exist so future connectors can inject facts into the same graph.
- Whether an LLM-authored recommendation actually cites real evidence is
  enforced through the prompt's Reasoning Goal, not verified
  deterministically afterward — matching how prior tasks handled
  LLM-authored content the Runtime cannot re-parse without NLP.
- The prior `CompanyContext` / `CompanySnapshot` / `DepartmentContext` /
  `DepartmentSnapshot` types are left in place (still independently
  tested) but are no longer used by `DailyAgent`, which now reasons over
  the Knowledge Graph instead.
