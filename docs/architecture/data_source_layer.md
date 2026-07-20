# Data Source Layer

## Why

The runtime previously asked the LLM to generate business decisions
without real company context, so it invented marketing campaigns,
product information, sales activity, links, locations, and dates.
Before Marketing, Sales, or Finance can make real decisions, the
runtime needs a unified way to collect information from the company's
actual systems.

The Data Source Layer is that foundation. It is architecture only:
this document, and the code it describes, introduce no real
integrations yet.

## Core Types

```
lib/data/data_source.dart
lib/data/data_snapshot.dart
lib/data/data_source_registry.dart
```

### `DataSource`

```dart
abstract interface class DataSource {
  String get id;

  Future<void> refresh(DataSnapshot snapshot);
}
```

A `DataSource` is a connector to one real-world company system (CRM,
social media, analytics, ...). Each `DataSource`:

- populates only its own section of the shared `DataSnapshot`,
- never talks to another `DataSource`,
- never depends on how any other `DataSource` loads or stores its own
  data.

### `DataSnapshot`

The shared runtime context. It will eventually carry information from
every company system the runtime can connect to. Initially — and for
every section no connector has populated yet — it stays empty.

`DataSnapshot` contains **no business logic**: no validation, no
computation, no interpretation. It is only a shared container that
`DataSource`s write into and that consumers (Marketing, Sales, Finance,
...) will eventually read from.

### `DataSourceRegistry`

```dart
final registry = DataSourceRegistry(
  sources: [
    CrmDataSource(workspaceRoot: workspaceRoot),
    SocialDataSource(workspaceRoot: workspaceRoot),
    // ...
  ],
);

await registry.refreshAll(snapshot);
```

The registry owns every available `DataSource` and refreshes them into
one shared `DataSnapshot`, **sequentially, in the given order**. There
is no parallel execution — each connector fully completes its
`refresh()` call before the next one starts.

## The HQ Workspace

The runtime must not assume company files live inside the runtime
repository. Instead, the runtime knows only the **HQ workspace root**
directory — an example layout:

```
pharos-hq/
    company/
    crm/
    marketing/
    finance/
    analytics/
    social/
    competitors/
    knowledge/
    assets/
```

Every connector receives this workspace root at construction time (as
`workspaceRoot`). Individual connectors decide, internally, how to
locate and load their own data beneath it. The runtime, the registry,
and every other connector never know:

- whether a connector reads an Excel file, a Google Sheet, a database,
  or calls an external API,
- where under the workspace root a connector's data actually lives,
- what format that data is stored in.

The storage technology stays entirely hidden behind the connector.

## Placeholder Connectors

Every connector currently implemented is a **placeholder**: it
implements `DataSource`, exposes a stable `id`, and its `refresh()`
completes without performing any HTTP requests, OAuth flows, browser
automation, or file I/O.

```
lib/data/connectors/crm/crm_data_source.dart              -> CrmDataSource         (id: "crm")
lib/data/connectors/social/social_data_source.dart        -> SocialDataSource      (id: "social")
lib/data/connectors/trends/trends_data_source.dart        -> TrendsDataSource      (id: "trends")
lib/data/connectors/news/news_data_source.dart             -> NewsDataSource        (id: "news")
lib/data/connectors/analytics/analytics_data_source.dart  -> AnalyticsDataSource   (id: "analytics")
lib/data/connectors/competitors/competitor_data_source.dart -> CompetitorDataSource (id: "competitors")
```

## Intended Future Data Sources

The connectors above are the first six. The Data Source Layer is
designed so that every one of the following can be added later as its
own `DataSource` implementation, without changing `DataSource`,
`DataSnapshot`, `DataSourceRegistry`, or any existing connector:

| Future source          | Fits into the architecture as...                                   |
| ----------------------- | -------------------------------------------------------------------- |
| CRM                     | `CrmDataSource` — implemented as a placeholder today                |
| Social Media            | `SocialDataSource` — implemented as a placeholder today             |
| Google Trends           | `TrendsDataSource` — implemented as a placeholder today             |
| Industry News           | `NewsDataSource` — implemented as a placeholder today                |
| Reddit                  | A new `DataSource`, or a future extension of `SocialDataSource`     |
| Competitor Monitoring   | `CompetitorDataSource` — implemented as a placeholder today          |
| Firebase Analytics      | A future extension of `AnalyticsDataSource`                          |
| GA4                     | A future extension of `AnalyticsDataSource`                          |
| Search Console          | A future extension of `AnalyticsDataSource`                          |
| Gmail                   | A new `DataSource`, populating its own snapshot section              |
| Calendar                | A new `DataSource`, populating its own snapshot section              |
| Finance                 | A new `DataSource`, populating its own snapshot section              |
| Lead Database           | A new `DataSource`, populating its own snapshot section              |
| Image Generator         | Not a `DataSource` — a generation capability consumed by a Workflow  |
| Video Engine            | Not a `DataSource` — a generation capability consumed by a Workflow  |
| SEO                     | A new `DataSource`, or a future extension of `AnalyticsDataSource`  |
| Advertising Platforms   | A new `DataSource`, populating its own snapshot section              |

No implementation of any of these is required by this document — it
only records how each one is expected to fit into the architecture
once it is built.

## What This Task Does Not Do

- No connector performs a real HTTP request, OAuth flow, browser
  automation, or file I/O.
- `DataSnapshot` and `DataSourceRegistry` are not wired into
  `ExecutionContext`, `DailyAgent`, or any other part of the running
  Runtime yet. `dart run bin/pharos.dart daily` behaves exactly as it
  did before this layer existed.
- `Runtime`, `ModelProvider`, `OpenAIProvider`, and `ExecutionPipeline`
  are untouched.
