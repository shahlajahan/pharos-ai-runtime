# ADR-0007

Title:
Streaming API Design

Status:
Proposed

---

## Context

The Conversation architecture is complete: `ModelRequest` is built entirely
from `Conversation`, and `Conversation` is the single source of truth for
everything sent to a model provider.

On top of that, the building blocks for streaming already exist:

- `StreamingResponse` — a provider-agnostic interface exposing
  `Stream<ModelResponseChunk>`.
- `ModelResponseChunk` — a chunk carrying an optional `textDelta`, an
  optional `toolCalls` fragment, and an `isFinished` flag.
- `StreamingResponseAggregator` — consumes a `StreamingResponse` and
  produces the same `ModelResponse` shape that a synchronous call would
  have produced.
- `HttpOpenAIClient.stream(...)` — the OpenAI transport already speaks
  Server-Sent Events and emits `ModelResponseChunk`s.

None of this is wired into a public entry point. `Runtime` has no public
streaming API: `run()` is synchronous only, and the only place the pieces
above are composed together is an unadvertised internal method
(`Runtime.streamAndAggregate`) that nothing calls yet.

This ADR exists because the next step — giving `Runtime` a real, public
streaming entry point — is a decision with long-term shape, not a small
task. It should be decided once, deliberately, rather than emerging
implicitly from whichever task happens to touch it first.

This ADR does not implement anything. It defines the target shape so that
future tasks (adding `Runtime.stream()`, wiring streaming into the
tool-calling loop, adding non-OpenAI providers) have a single design to
build toward.

## Decision

`Runtime` will eventually expose two parallel, symmetrical entry points:

```
Future<Result?> run(List<String> args, {HQSource? source})
Stream<ModelResponseChunk> stream(List<String> args, {HQSource? source})
```

`stream()` is the only new public surface. It does not replace `run()`;
both remain first-class, permanently. Naming it `stream()` rather than
`runStream()` (or similar) is deliberate: `ModelProvider` already
distinguishes its two execution modes as `generate()` and `stream()`, and
`Runtime`'s public API should use the same pair of verbs rather than
inventing a second convention. A `run`-prefixed streaming method would
read as a variant of `run()`; `stream()` reads as what it is — a sibling
entry point with its own identity, not a helper hung off `run()`.

`stream()`:

- Emits `ModelResponseChunk`s as the model produces them. Exactly which
  turns are exposed this way — the final assistant turn only, or also
  intermediate tool-calling rounds — is not settled by this ADR; see
  "Open Questions" below.
- May aggregate the streamed chunks into a complete `ModelResponse` when
  a fully-formed result is required — for example, before the
  tool-calling loop can decide whether to invoke a tool, or before
  handing a result to `EmployeeResponseHandler`. `StreamingResponseAggregator`
  is the default, reusable implementation of that aggregation step, but
  `Runtime` is not architecturally required to route every streaming call
  through it — a future execution path that never needs a final
  `ModelResponse` (e.g. a pure passthrough to a UI) is not precluded by
  this design.
- When `Runtime` does aggregate a streamed response into a final
  `ModelResponse` via `StreamingResponseAggregator`, that result is
  byte-for-byte equivalent to what `run()` would have produced for the
  same conversation — streaming is a delivery-mechanism choice, not a
  behavior change. This mirrors the guarantee already established and
  tested for `StreamingResponseAggregator` and `Runtime.streamAndAggregate`.

`ModelProvider` keeps its current two-method shape (`generate()`,
`stream()`) unchanged. No new abstractions are introduced at the provider
layer.

## Responsibilities

### Runtime

- Decides *whether* a given execution is synchronous or streaming
  (`run()` vs `stream()`), and resolves the employee/agent, builds the
  `ModelRequest` via `RuntimeRequestBuilder`, exactly as it does today.
- Owns the tool-calling loop in both modes: when `response.toolCalls` is
  non-empty, `Runtime` executes tools via `ToolInvoker`, appends
  `AssistantMessage`/`ToolMessage` to the `Conversation`, and issues a
  follow-up request — regardless of whether the *individual* model calls
  inside that loop were synchronous or streamed.
- Owns handing the final result to `EmployeeResponseHandler` (`run()`) or
  to the caller as a chunk stream (`stream()`).
- Never parses provider wire formats and never knows what SSE, WebSockets,
  or any other transport-level framing is.

### StreamingResponseAggregator

- Owns exactly one thing: turning a `Stream<ModelResponseChunk>` into a
  `ModelResponse`, by accumulating `textDelta` and `toolCalls` until
  `isFinished`.
- Has no knowledge of `Runtime`, `Conversation`, tool execution, or any
  specific provider. It operates purely on the `StreamingResponse`
  abstraction.
- Remains stateless between calls — one aggregator instance can safely
  aggregate many independent streams.

### ModelProvider

- Owns translating a provider-agnostic `ModelRequest` into a provider
  call, in both synchronous (`generate()`) and streaming (`stream()`)
  form, and translating the provider's response back into
  provider-agnostic `ModelResponse` / `StreamingResponse` types.
- Owns all provider-specific transport concerns: authentication, wire
  format, and — for streaming — the specific event-framing protocol
  (SSE for OpenAI today; a different framing is expected for other
  vendors).
- Is the only layer permitted to know that "OpenAI" exists. Nothing above
  it (`Runtime`, `StreamingResponseAggregator`, `Conversation`) may.

## Future Providers

Adding Anthropic, Gemini, or a local model means implementing a new
`ModelProvider` (e.g. `AnthropicProvider`, `GeminiProvider`) backed by a
new transport client (e.g. `HttpAnthropicClient`, analogous to
`HttpOpenAIClient`). That client is responsible for:

- Serializing `Conversation` into that vendor's request shape.
- For `stream()`: parsing that vendor's event framing (which will not be
  OpenAI-style SSE `data: {...}` / `data: [DONE]` — Anthropic and Gemini
  each have their own event shapes) and emitting the same
  `ModelResponseChunk` type OpenAI's client emits.

No other layer changes. `Runtime`, `StreamingResponseAggregator`,
`Conversation`, and `ToolInvoker` require zero modifications to support a
new provider — this is the architecture's central bet, and the reason
`ModelResponseChunk` is intentionally minimal and provider-neutral
(`textDelta`, `toolCalls`, `isFinished` — nothing OpenAI-specific like
`finish_reason` or `logprobs` leaks through it).

## Provider-Specific vs Runtime-Generic

Provider-specific (lives in `lib/models/<provider>/...`):

- Wire format serialization/deserialization (JSON shape, headers, auth).
- Event-framing parser for streaming (SSE today; whatever the next vendor
  uses next).
- Vendor error-response mapping into the shared exception hierarchy
  (e.g. `OpenAIException` today; a `ModelException` subtype per vendor in
  general).

Runtime-generic (lives in `lib/models/*.dart` and `lib/runtime/*.dart`,
independent of any vendor):

- `Conversation` and all `Message` subtypes.
- `ModelRequest`, `ModelResponse`.
- `StreamingResponse`, `ModelResponseChunk`.
- `StreamingResponseAggregator`.
- `ToolDefinition`, `ToolCall`, `ToolOutput`, `ToolRegistry`, `ToolInvoker`.
- `Runtime`, `RuntimeRequestBuilder`, `EmployeeResponseHandler`.

The dividing line is exactly the `ModelProvider` interface: everything
behind it may be vendor-specific; everything in front of it must not be.

## Trade-offs

Advantages of this design:

- Adding a provider is additive and isolated — confirmed by the fact that
  `StreamingResponseAggregator` and `Runtime` needed zero changes when
  OpenAI streaming transport was implemented; the same should hold for
  the next provider.
- Streamed and synchronous execution are guaranteed to converge on the
  same final `ModelResponse`, so callers (and `EmployeeResponseHandler`)
  never need provider- or mode-specific handling.
- Each layer is independently unit-testable, which is already proven in
  practice: `StreamingResponseAggregator` is tested with zero dependency
  on any provider, and `HttpOpenAIClient.stream()` is tested with zero
  dependency on `Runtime`.

Disadvantages / open costs:

- What exactly gets streamed across a multi-round tool-calling execution
  is not yet decided — see "Open Questions" below. Until it is, callers
  of `stream()` cannot rely on a fixed contract for tool-calling rounds.
- `stream()` and `run()` are two parallel code paths through the same
  tool-calling loop; keeping their behavior identical (same message
  ordering, same tool execution semantics) is an ongoing discipline cost,
  not something the type system enforces for us.
- When `Runtime` does aggregate via `StreamingResponseAggregator`,
  buffering means very large streamed responses hold their full
  accumulated text and tool calls in memory before `Runtime` can act on
  them — acceptable at today's scale, but a real constraint if response
  sizes grow substantially.

## Open Questions

**Which turns does `stream()` expose to the caller?**
This ADR intentionally leaves this open rather than freezing it. One
constraint is fixed regardless of the answer: a tool call's `arguments`
must be complete before `ToolInvoker` can safely execute it, so
intermediate tool-calling rounds must always be fully aggregated
*internally* before `Runtime` acts on them — that much follows directly
from `ToolInvoker`'s contract, not from a streaming-API choice. What is
not fixed is whether `Runtime.stream()` surfaces chunks to the *caller*
only for the final assistant turn, or also exposes the intermediate
tool-calling rounds (e.g. so a caller can show "the model is calling
`search`..." while waiting). Deciding this now would be premature: it
depends on product needs that have not been established yet. It should
be resolved by a future, narrower ADR or task once a concrete caller
need exists — see "Expose `Stream<ModelResponseChunk>` from every
intermediate tool-calling round" under Alternatives Considered for the
design this would imply.

## Alternatives Considered

**Callback-based streaming (`onChunk: (ModelResponseChunk) => void`)**
Rejected. Callbacks do not compose with `async`/`await`, are harder to
test deterministically, and are inconsistent with the `Stream`-based
idiom already used throughout this codebase. This was also explicitly
ruled out when `ModelProvider.stream()` was first introduced.

**`run()` returns a union of `Result` or `Stream<ModelResponseChunk>`**
Rejected. It would change `run()`'s existing, stable contract
(`Future<Result?>`) for every caller, including ones that never want
streaming, and would complicate the tool-calling loop, which needs a
fully aggregated response before it can decide whether to invoke tools.
A separate `stream()` method keeps `run()` untouched.

**Each `ModelProvider` implementation owns its own aggregation logic**
Rejected. This would duplicate the identical accumulate-until-`isFinished`
logic across every provider (OpenAI, Anthropic, Gemini, ...) instead of
once in `StreamingResponseAggregator`, and would make it possible for
providers to subtly diverge in how they define "done."

**Fold `StreamingResponseAggregator`'s logic directly into `Runtime`**
Rejected. This was tried and reverted: it made the aggregation logic
untestable in isolation and pushed `Runtime` toward a growing public
surface area just to make internals testable. Keeping aggregation in its
own class, injected into `Runtime`, keeps `Runtime`'s public API stable
while the aggregation logic remains independently verifiable.

**Expose `Stream<ModelResponseChunk>` from every intermediate tool-calling
round, not just the final turn**
Rejected for now. It would require `ToolInvoker` to either speculate on
incomplete tool-call arguments or block mid-stream waiting for
completion, and would expose provider-level granularity
(one chunk per SSE event) as an application-level contract. If a future
product need justifies this, it should be a new, explicitly-scoped ADR,
not an extension of this one.
