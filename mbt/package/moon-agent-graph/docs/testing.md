# Moon Agent Graph Runtime Test Coverage

## Purpose and Status

This document reconciles the reviewed MVP test plan with the deterministic native test suite implemented in `mbt/package/moon-agent-graph`.

The suite is native-only, uses no provider credentials, and exercises public graph, runtime, node, coding-agent, MoonLLM, Codex, and OpenCode boundaries with deterministic fakes or local processes.

At this reconciliation point, the module contains 105 MoonBit test blocks: 57 core tests, 6 MoonLLM unit tests, 7 coding-agent-node tests, 10 shared-testing tests, 4 Codex unit tests, 1 OpenCode unit test, 2 visualization tests, and 18 cross-package integration tests.

The identifiers below remain useful acceptance traceability from the original plan. “Automated” means a deterministic native test currently covers the described public behavior. “Deferred” means the behavior still needs a manual or credentialed remote-provider exercise and is not claimed by normal CI.

## MoonBit Test Conventions

- Name every implementation-adjacent unit test file exactly `<implementation-basename>_test.mbt` after the implementation file it exercises.
- Keep lifecycle, error, and cancellation cases for one implementation in that unit-test file; alternate adjacent suffixes such as `_lifecycle_test.mbt`, `_error_test.mbt`, and `_wbtest.mbt` are not allowed.
- Place tests that connect multiple packages under `src/test/` as black-box integration tests. Split them into files named for the integration boundary or workflow scenario.
- Exercise package-private behavior through its public observable surface instead of coupling tests to private helpers.
- Use `async test` for async behavior and preserve cancellation errors instead of converting them into ordinary failures.
- Assume async tests may run in parallel, so every native-process test owns a unique temporary directory and ephemeral localhost port.
- Bound polling with `@testing.eventually` or `@async.with_timeout` and do not depend on execution order.
- Inspect typed errors and observable event order rather than internal implementation details.
- Keep real remote-model and credentialed-provider checks outside normal CI.

## Test Layers

| Layer                 | Current deterministic surface                                                               |           Normal CI |
| --------------------- | ------------------------------------------------------------------------------------------- | ------------------: |
| Core unit and runtime | IDs, graph compilation, nodes, events, resources, lifecycle, sequential runtime             |                 Yes |
| MoonLLM node          | Typed callback fake plus local OpenAI-compatible HTTP server                                |                 Yes |
| Coding-agent node     | Fake session lifecycle, scope, retry, cancellation, and response decoding                   |                 Yes |
| Codex adapter         | Repository SDK against a native fake executable                                             |                 Yes |
| OpenCode adapter      | Repository CLI SDK against a native fake `opencode run` executable                          |                 Yes |
| Workflow E2E          | Function, fake coding-agent, fake MoonLLM, routing, retry, failure, and cancellation graphs |                 Yes |
| Real remote-agent E2E | Actual provider credentials, model behavior, and user workspace effects                     | Manual and deferred |

## Shared Deterministic Fixtures

The `testing` package currently provides the following fixtures and helpers:

- `scripted_node` records a node’s public context and state inputs.
- `scripted_router` records router state and completion inputs.
- `recording_reducer` records state and patch inputs.
- `recording_event_sink` records the exact emitted `GraphEvent` sequence.
- `fake_coding_agent` records opens, requests, session IDs, and close order while optionally raising injected open or execute errors.
- `fake_moonllm_invoke` records typed `@llm.ChatRequest` values while optionally raising an injected error.
- `temporary_workspace` creates a unique temporary root and removes it idempotently through `close`.
- `eventually` polls an async predicate with a mandatory bounded timeout.
- `process_is_running` and `localhost_port_is_open` observe native process and localhost-port cleanup without shell parsing in product tests.

Fixture state belongs to one test. Tests that coordinate child tasks keep mutation in one owner task or use the async mutex exposed by the production boundary.

## Plan ID Traceability

| ID family                                  | Current status                              | Deterministic evidence                                                                                                                                                                                                |
| ------------------------------------------ | ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ID-*`                                     | Automated                                   | Parsing, equality, hash-map use, text conversion, and empty-ID errors in `src/core/identifiers_test.mbt`                                                                                                              |
| `GRAPH-*`                                  | Automated                                   | Duplicate, missing, unknown, cyclic, unreachable, compiled-snapshot isolation, and undeclared-route behavior in `src/core/graph_test.mbt`                                                                             |
| `to_mermaid`                               | Automated                                   | Deterministic escaping, node and router descriptions, route labels, and branch ordering in `src/visualization/mermaid_test.mbt`                                                                                       |
| `FN-*`, `ROUTER-*`, `REDUCER-*`, `EVENT-*` | Automated                                   | Function-node context and cancellation, reducer/router ordering, lifecycle events, and sink failure isolation in `src/core/model_test.mbt`                                                                            |
| `RESOURCE-*`                               | Automated                                   | Run/node ownership, cache behavior, reverse close order, close-once, aggregated cleanup errors, timeout, and cancellation protection in `src/core/resources_test.mbt`                                                 |
| `RUNTIME-*`                                | Automated                                   | Sequential execution, state reduction, route contract, explicit failure, step limit, timeout, cancellation, cleanup composition, and invocation isolation in `src/core/runtime_test.mbt` and `runtime_types_test.mbt` |
| `LLM-*`                                    | Automated except remote-provider behavior   | Callback and error boundaries in `src/moonllm/llm_node_test.mbt`, plus local mock HTTP integration in `src/test/moonllm_test.mbt`                                                                                     |
| `AGENT-*`, `AGENTNODE-*`                   | Automated                                   | Common contract, run/node scope, continuation, retry, failure phase, cancellation, and close semantics in `src/coding_agent/coding_agent_node_test.mbt` and `src/testing/fakes_test.mbt`                              |
| `CODEX-*`                                  | Automated for local adapter boundary        | Unit mapping in `src/integrations/codex/codex_agent_test.mbt`, plus native CLI, runtime cancellation, and cleanup integration in `src/test/codex_test.mbt`                                                            |
| `OPENCODE-*`                               | Automated for local adapter boundary        | Option construction in `src/integrations/opencode/opencode_agent_test.mbt`, plus CLI mapping, environment, continuation, failure, cancellation, and cleanup in `src/test/opencode_test.mbt`                           |
| `E2E-*`                                    | Automated for deterministic graph workflows | MoonLLM-plan-to-function verification, agent retry, branch selection, bounded loop, planning failure, and cancellation workflows in `src/test/workflow_test.mbt`                                                      |
| Real provider-specific behavior            | Deferred                                    | Run manually with explicit credentials and a disposable workspace; it is not part of normal CI                                                                                                                        |

## Core and Runtime Coverage

The core suite proves identifier validation, graph compilation, compiled-graph snapshot isolation, node context construction, synchronous sink ordering, resource ownership, and sequential runtime behavior.

The runtime tests cover successful one-node and multi-node graphs, reducer-before-router ordering, no-patch behavior, undeclared target rejection, explicit `Route::Fail`, invalid options, exact step-limit attempts, timeout, cancellation, cleanup error composition, and isolated repeated invocation.

The expected successful lifecycle remains:

```text
RunStarted
NodeStarted
NodeCompleted
StateUpdated, when a patch exists
RouteSelected
RunCompleted
```

Failure and cancellation tests additionally verify exactly one terminal event after `RunStarted`.

## MoonLLM Node Coverage

`src/moonllm/llm_node_test.mbt` covers the narrow `LlmNodeSpec` boundary with a typed `ChatRequest` built from state, one async fake invocation, decoded patch/value/artifact output, usage metadata, runtime state application, builder failure, preserved `LLMError`, decoder failure without reducer execution, and cancellation of a paused callback.

`src/test/moonllm_test.mbt` connects the public graph node to a local OpenAI-compatible mock server through the real MoonLLM client and verifies request mapping, response decoding, state updates, and usage artifacts.

Structured-output behavior beyond the current chat-completion boundary remains a future adapter-specific test, not an implemented claim.

## Coding-Agent and Adapter Coverage

The coding-agent-node tests use deterministic sessions to verify run-scoped reuse, node-scoped close behavior, builder and execute failure boundaries, decoder failure without state update, continuation propagation, retry after failed open, and caller cancellation cleanup.

`src/test/codex_test.mbt` uses a fake native executable and the repository SDK. It verifies option and workspace mapping, start-versus-resume continuation behavior, streamed summary and changed-file mapping, `turn.failed` propagation, cancellation through `GraphRuntime`, subprocess termination, and cleanup.

`src/test/opencode_test.mbt` uses a fake `opencode run --format json` executable. It verifies CLI option and prompt mapping, context-file attachment, inherited/adapter/caller environment precedence, new and resumed session IDs, repeated turns through one logical session, exact process-exit failure propagation, and `SessionClosed` after an idempotent public close.

OpenCode cancellation follows the shared CLI ownership contract: cancelling an in-flight `execute` hard-stops and awaits its child process before returning cancellation. The integration test observes the child PID while the fake executable is blocked, cancels the task, proves the PID is no longer alive, and then closes the logical session.

The OpenCode CLI SDK's dedicated tests cover typed JSONL decoding, malformed records, error events, callback streaming, process exits, and direct cancellation. The graph adapter tests keep their scope to adapter mapping and public session behavior.

## Workflow E2E Coverage

`src/test/workflow_test.mbt` connects `core`, `e2e`, `moonllm`, `coding_agent`, and `testing`. It covers deterministic function-only order, a typed MoonLLM-plan-to-function-verify path, Codex-labelled and OpenCode-labelled fake-agent workflows, both branch inputs, exact bounded-loop attempts and `StepLimitExceeded`, injected LLM planning failure, and cancellation of a blocked coding-agent workflow. It proves run-scoped session reuse, exact request counts, unselected agents remaining unopened, unchanged initial state after planning failure, no later LLM node after cancellation, one session close, and one emitted `RunCancelled` event.

The original real-adapter workflow diagrams remain useful as manual acceptance scenarios, but normal CI currently uses deterministic local boundaries instead of real provider credentials or a user workspace.

```mermaid
flowchart LR
  Plan["MoonLLM plan"] --> Implement["Coding agent"]
  Implement --> Test["Function test"]
  Test -->|"pass"| End(("End"))
  Test -->|"retry remains"| Implement
  Test -->|"limit reached"| Fail(("Fail"))
```

## Native Commands

Run commands from the repository root.

```bash
vp run mbt:fix
vp run mbt:check
vp run mbt:build
vp run mbt:test
```

Use a selected-file command while developing a focused test, then run its package before relying on a module-wide gate.

```bash
moon test mbt/package/moon-agent-graph/src/test/workflow_test.mbt --target native --deny-warn
moon check mbt/package/moon-agent-graph/src/test/workflow_test.mbt --target native --deny-warn
moon test mbt/package/moon-agent-graph/src/test --target native --deny-warn
```

The final implementation gate runs the root MoonBit check, build, and test tasks. A focused test result does not replace that gate.

## Deferred Manual Checks

- Run a real MoonLLM provider against a disposable account and confirm provider-specific model behavior.
- Run Codex and OpenCode against disposable real workspaces and verify their external process behavior under the installed versions.
- Validate structured-output APIs if a future node uses a request/response pair other than `ChatRequest` and `ChatResponse`.
- Perform credential-redaction review against real provider error payloads without recording credentials in test artifacts.

## Acceptance Criteria

- All deterministic native tests pass through the root MoonBit gate.
- Every process-owning failure or close path proves PID, port, and temporary-root cleanup on its matching local surface.
- Cancellation tests use real task cancellation and preserve cancellation semantics.
- No test fabricates SDK fields that the SDK does not expose.
- Normal CI requires no provider credentials.
- Deferred remote checks remain explicitly manual until a credentialed test environment is intentionally added.

## References

- [MoonBit async programming and async tests](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBit build-system test file conventions](https://docs.moonbitlang.com/en/latest/toolchain/moon/tutorial.html)
- [MoonBit package test imports](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- [moonbitlang/async package documentation](https://mooncakes.io/docs/moonbitlang/async)
