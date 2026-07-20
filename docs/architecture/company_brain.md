# Company Brain — Grounding the Runtime on HQ

## Why

Before this task, agents asked the LLM to generate business content
with no real company facts behind it. The result looked plausible but
was invented: campaigns, KPIs, customers, marketing activities, links,
and metrics that do not exist. This document describes the first real
step toward the **Company Brain**: a Runtime that reasons from the
company's actual HQ Workspace instead of fabricating it.

This task grounds the Runtime on HQ. It does not implement any live
integration — see [`data_source_layer.md`](./data_source_layer.md) for
the separate, future-facing connector architecture (CRM, social,
analytics, ...) that will eventually feed richer data into this same
grounding pipeline.

## Core Types

```
lib/company/company_document.dart
lib/company/company_loader.dart
lib/company/company_context.dart
lib/company/company_context_builder.dart
```

### `CompanyDocument`

One document loaded from the HQ Workspace, tagged with the category
(folder) it came from — for example `company`, `products`, or
`social`.

### `CompanyLoader`

```dart
const loader = CompanyLoader();
final documents = await loader.load(workspaceRoot);
```

Reads every document under the HQ workspace root, from these
categories at minimum:

```
company/
knowledge/
products/
assets/
services/
websites/
social/
analytics/
```

This is the **only** place company facts are read from disk. A missing
category folder — or a missing workspace root entirely — is ignored:
`CompanyLoader` never fails just because a folder does not exist. It
performs no HTTP requests, no OAuth, no browser automation, and no
parsing beyond reading each file's raw text content.

### `CompanyContext`

The structured knowledge given to an agent — one section per category,
each a list of normalized entries (`"name: content"`). Sections with no
matching documents stay empty rather than being invented. `CompanyContext`
contains no raw markdown and no business logic: it is a pure data
container.

### `CompanyContextBuilder`

```dart
const builder = CompanyContextBuilder();
final context = builder.build(documents);
```

Transforms loaded `CompanyDocument`s into one `CompanyContext`. Purely
synchronous context assembly: no LLM calls, no business decisions, no
prompt generation. It only groups documents by category and strips
markdown heading markers.

## The Daily Agent's Grounded Flow

```
Load HQ
   |
   v
Build Company Context
   |
   v
Build Daily Prompt
   |
   v
Call LLM
```

`DailyAgent` resolves the HQ workspace root (constructor override, then
the `PHAROS_HQ_ROOT` environment variable, then a `pharos-hq` default),
loads every `CompanyDocument` it can find there, builds one
`CompanyContext`, and sends **one** prompt to the configured
`ModelProvider` containing that context plus explicit anti-hallucination
instructions. The LLM's response becomes the daily report body.

## Prompt Rules

Every daily prompt explicitly instructs the model to:

- Never invent company facts.
- Use only the supplied Company Context.
- State explicitly when information is unavailable.
- Never fabricate KPIs, campaigns, revenue, customers, metrics,
  analytics, or marketing activities.
- Prefer `Unknown`, `Unavailable`, or `Not yet connected` over
  fabricated information.

When a `CompanyContext` section has no entries (nothing was found under
that HQ category), the prompt renders it as `Not yet connected` rather
than omitting it — the model is told, explicitly, what is missing
instead of being left to guess or invent.

## Example

Instead of:

> Yesterday we achieved a 15% increase...

a grounded report says:

> No live analytics are currently connected.
>
> Known marketing assets:
> - Instagram
> - LinkedIn
> - Firebase Analytics
> - GA4

Instead of a fabricated "Today's campaign", the report reasons from
whatever company vision, product positioning, available assets,
documented channels, and known capabilities were actually found in the
HQ Workspace.

## What This Task Does Not Do

- No CRM, Analytics, GitHub, Gmail, Calendar, Firebase, or Search
  Console connector is implemented.
- No live integrations of any kind — `CompanyLoader` only reads local
  files already present under the HQ workspace root.
- The Workflow Engine, Tool Registry, `ModelProvider`, and
  `ExecutionPipeline` are untouched.
- `CompanyRegistry` / `CompanyProduct` / `DailyMarketingPrompt` (the
  per-product marketing prompt introduced earlier) are left in place
  but are no longer used by `DailyAgent` — the daily report is now one
  grounded company report, not a per-product list of invented marketing
  copy.
