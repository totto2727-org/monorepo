# Topcoat and Datastar Web UI

Use this reference for server-driven Rust web applications, especially local operational consoles, dashboards, workflow UIs, and applications where the server owns authoritative state.

## Contents

- [Why Topcoat](#why-topcoat)
- [Why Datastar](#why-datastar)
- [Combined responsibilities](#combined-responsibilities)
- [Topcoat reactivity versus Datastar reactivity](#topcoat-reactivity-versus-datastar-reactivity)
- [Initial render and navigation](#initial-render-and-navigation)
- [Minimal SSE payloads](#minimal-sse-payloads)
- [SSE endpoint boundaries](#sse-endpoint-boundaries)
- [Replay and reconnection](#replay-and-reconnection)
- [Security and observability](#security-and-observability)
- [Official sources](#official-sources)

## Why Topcoat

Topcoat keeps routing, typed request extraction, Rust view composition, application context, assets, and SSE responses in one Rust application. Prefer it when sharing types and rendering logic with the backend is more valuable than maintaining a separate JavaScript application and API client.

Use Topcoat views as the canonical HTML generator. Keep components aligned with independently rendered or patched page regions, and preserve stable element IDs at patch boundaries.

Topcoat is less suitable when the product must run mostly offline, needs a large client-only state machine, or depends on an established frontend ecosystem that should remain the primary application runtime.

## Why Datastar

Datastar adds declarative browser actions, reactive signals, and SSE-driven element or signal patches without requiring application-specific JavaScript for common interactions. Prefer it when the browser should remain a thin projection of server state.

Use element patches for server-rendered UI and signal patches for small client-facing values. Keep domain state, workflow state, authorization, filtering, and history on the server.

Do not treat signals as an untyped global store. Use them for ephemeral UI state such as selected controls, pending state, or a trace target. Put durable and shareable state in a canonical URL or the server domain model.

## Combined responsibilities

| Concern                                                                   | Owner                                            |
| ------------------------------------------------------------------------- | ------------------------------------------------ |
| Route matching, request parsing, authorization, and response construction | Topcoat handler and application services         |
| Canonical HTML and component composition                                  | Topcoat Rust views                               |
| Browser events and small reactive expressions                             | Datastar attributes and signals                  |
| Partial DOM or signal updates                                             | Datastar SSE events produced by Topcoat handlers |
| Durable workflow, run, filter, and history state                          | URL plus server domain model                     |

Keep one authoritative owner for each state value. Do not independently model the same state in a Topcoat runtime signal, a Datastar signal, a cookie, and a server object.

## Topcoat reactivity versus Datastar reactivity

Use a Topcoat `#[shard]` when a cohesive component should re-run on the server whenever its reactive arguments change and replacing the shard as a unit is acceptable. State declared inside a shard resets when the shard is replaced, so state that must survive belongs outside the shard and flows in through arguments.

Treat shard arguments as untrusted request input. A shard is exposed as its own endpoint, so it must perform the authorization and argument validation required by the rendered data instead of assuming page or layout guards already ran.

Use Datastar when interactions cross component boundaries, require explicit backend actions, need independently reconnectable SSE streams, or patch smaller regions than a whole shard. Datastar is also the clearer choice when the backend must push changes that did not originate from a local input event, such as cron runs or workflow progress.

Do not make both systems react to the same change. Choose the smallest cohesive owner and document the request, patch, and state lifecycle.

## Initial render and navigation

Return a complete and readable initial document through normal HTTP SSR. Use SSE for later changes, not as a prerequisite for the first meaningful render.

Represent workflow selection, run selection, and shareable filters in canonical paths and query parameters. Normalize invalid or default filter values on the server, preserve active filters in links and redirects, and let reload, sharing, back, and forward navigation reconstruct the same view.

Use server-rendered forms for workflow-owned inputs. Let each workflow module own its form fields, typed input DTO, parsing, validation, defaults, graph definition, topology metadata, and schedules; let the application registry import definitions without branching on workflow-specific fields.

## Minimal SSE payloads

Avoid sending a full collection and filtering it in the browser. If one row changes in a 100-row history, sending 100 rows on every update wastes network, rendering, and reconciliation work.

Prefer server-side filtering followed by a delta for the already filtered visible set. Generate no event when a mutation does not change the subscribed view.

| Avoid                                              | Prefer                                                                              |
| -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Send every history row, then filter in the browser | Parse the filter on the server and patch only an inserted, replaced, or removed row |
| Replace a whole panel for one status field         | Patch the smallest stable panel or element boundary that remains coherent           |
| Send an event for every domain mutation            | Send nothing when the mutation has no visible effect for this subscription          |
| Use SSE as the initial page snapshot               | Render the snapshot with HTTP SSR and start SSE after its revision                  |

For a filtered collection, classify each mutation against membership before and after the change:

| Before   | After    | Visible operation |
| -------- | -------- | ----------------- |
| excluded | included | insert            |
| included | included | replace           |
| included | excluded | remove            |
| excluded | excluded | no event          |

Track the visible membership for the stream so an empty-state row is added only after the last matching item is removed.

## SSE endpoint boundaries

Avoid a universal SSE endpoint that combines unrelated graph, trace, log, and history HTML into every response.

Split streams when their update cadence, selected data, rendered HTML boundary, or reconnect lifecycle differs. For example, a selected run stream can own its graph and step trace while a history stream owns filtered table rows.

Do not split streams mechanically. Keep updates together when they must always share one revision, patch the same cohesive HTML boundary, and recover as one unit. The correct boundary depends on state ownership, timing, payload, and consistency requirements; there is no universal endpoint count.

When streams share a data source but not a connection, define how they synchronize. Give each stream an explicit revision or snapshot contract and do not assume browser arrival order across connections.

## Replay and reconnection

Maintain a monotonically increasing revision and a bounded replay journal when a stream must recover changes after disconnecting.

Subscribe to live notifications before reading the snapshot or replay boundary, but do not rely on subscription order alone. Buffer live notifications or serialize snapshot, journal, and subscription access while establishing a revision boundary; replay retained revisions through that boundary, then drain buffered revisions above it in order before consuming the live stream. Ignore duplicates at or below the last applied revision. An equivalent single serialized journal protocol is also valid when it proves the same ordering and loss-free handoff.

Assign the logical revision to the SSE event ID and resume from `Last-Event-ID`. Treat that header as untrusted input: limit its size, parse it into the expected revision type, and reject it or request a fresh snapshot when it is malformed or outside the retained range. One logical revision must be reconnect-atomic: encode all visible DOM changes for that revision in one SSE event, or use a finer cursor that can resume each sub-change independently. Never emit multiple complete events with the same revision ID because reconnecting after the first event would skip the remaining events.

Reload or request a fresh SSR snapshot when the cursor is older than the bounded journal, ahead of the server, separated by a revision gap, or lost through receiver lag. Do not apply a partial replay after consistency is no longer provable.

Use SSE keepalive comments for idle connections, but do not assign them domain revisions. Bound live broadcast queues and treat a slow receiver that falls behind as a resynchronization case instead of silently dropping changes.

An in-memory journal and broadcast channel coordinate only one process. Use a shared durable event log or broker with explicit bounded retention or compaction when multiple server processes must resume the same revisions.

Use stable IDs on patch roots. Choose `prepend`, `outer`, `inner`, or `remove` based on the actual DOM operation, and keep a logical revision to one atomic patch event whenever resumption uses that revision.

## Security and observability

Validate path parameters, query filters, Datastar signals, and shard arguments at the server boundary. Do not trust hidden fields, signals, or selectors because the caller can construct requests directly.

Authenticate and authorize every SSE connection, including reconnects. Scope the initial snapshot, replay lookup, server-side filter, and live notification stream to the authenticated principal or tenant and the permitted workflow or run; possession of a run ID or replay cursor is not authorization.

Log the listening URL and completed request method, normalized route template or redacted path, status, and elapsed time with `tracing`. Omit query strings by default and allowlist individual query fields only after confirming they are safe. Do not log secrets, complete workflow inputs, LLM prompts, or model responses by default.

## Official sources

- [Topcoat Datastar integration](https://github.com/tokio-rs/topcoat/blob/371c7403fcbf4d40bbacb2f87eb98d9ce00e76c8/crates/topcoat/docs/datastar.md)
- [Topcoat shard behavior](https://github.com/tokio-rs/topcoat/blob/371c7403fcbf4d40bbacb2f87eb98d9ce00e76c8/crates/topcoat-runtime/macro/docs/shard.md)
- [Topcoat `PatchElements`](https://github.com/tokio-rs/topcoat/blob/371c7403fcbf4d40bbacb2f87eb98d9ce00e76c8/crates/topcoat-datastar/src/patch_elements.rs#L38-L75)
- [Topcoat SSE event IDs](https://github.com/tokio-rs/topcoat/blob/371c7403fcbf4d40bbacb2f87eb98d9ce00e76c8/crates/topcoat-router/src/content/sse/event.rs#L67-L85)
- [Datastar backend requests](https://data-star.dev/guide/backend_requests)
- [Datastar reactive signals](https://data-star.dev/guide/reactive_signals)
- [Datastar SSE events](https://data-star.dev/reference/sse_events)
- [The Tao of Datastar](https://data-star.dev/guide/the_tao_of_datastar)

Topcoat and Datastar evolve quickly. Verify the selected release's APIs before implementation and prefer release or commit-pinned source links when recording a version-specific decision.
