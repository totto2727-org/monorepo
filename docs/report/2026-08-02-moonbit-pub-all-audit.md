# MoonBit `pub(all)` audit

## Executive summary

The audit scope contains 126 `pub(all)` type declarations across eight MoonBit modules: 78 structs, 32 enums, and 16 suberrors. Only 18 declarations have a clear contract that requires callers to construct enum variants directly. Another 37 declarations need external construction but should expose it through an existing or new constructor or narrowly scoped factory. The remaining 71 declarations are outputs, errors, runtime-owned contexts, or test observations and should normally be readonly `pub` types.

`totto2727/geo-mbt` is temporarily excluded from this audit. Its 19 `pub(all)` declarations are not included in any count or recommendation below.

The recommended default is therefore `pub`, not `pub(all)`. Use `pub(all)` only when direct construction of every representable value is intentionally part of the public contract and there is no invariant, normalization, ownership, lifecycle, or compatibility boundary to preserve.

| Recommendation                                                | Count | Meaning                                                                                              |
| ------------------------------------------------------------- | ----: | ---------------------------------------------------------------------------------------------------- |
| Keep `pub(all)`                                               |    18 | Direct enum-variant construction is an intentional input contract.                                   |
| Change to `pub`; keep an existing constructor or factory      |    21 | External construction is valid, but callers should use the canonical path already present.           |
| Change to `pub`; add a constructor or factory                 |    16 | External construction is valid, but the package needs a canonical path before visibility is reduced. |
| Change to readonly `pub`; do not expose external construction |    71 | The type is an output, error, runtime-owned value, or test observation.                              |

These recommendations were applied on 2026-08-04. Excluding `geo-mbt`, only the 18 intentional input enums remain `pub(all)`; other construction now goes through constructors, narrowly scoped factories, or package-internal code.

## Official language basis

MoonBit defines `pub` types as readonly outside their defining package: external packages may inspect fields and pattern-match values, but may not construct them or update their fields. `pub(all)` additionally permits external construction and mutation where the representation allows it. The same-package implementation is not restricted by `pub`, so the package can still implement constructors and decoders that return readonly public types. See [Managing Projects with Packages: Access Control](https://docs.moonbitlang.com/en/latest/language/packages.html#access-control).

MoonBit distinguishes white-box tests, which can access every package member, from black-box tests, which see only the public API. A test that needs an invalid internal value should use a white-box test when it is testing implementation behavior; it should not expand the production API merely to make black-box setup convenient. See [Writing Tests: BlackBox Tests and WhiteBox Tests](https://docs.moonbitlang.com/en/latest/language/tests.html#blackbox-tests-and-whitebox-tests).

Enum constructors cannot be assigned visibility independently. When an enum must be externally observable but not freely constructible, use a readonly `pub enum` and expose only the necessary package functions that return its values. See [MoonBit diagnostic E3006](https://docs.moonbitlang.com/en/latest/language/error_codes/E3006.html).

For already published APIs, MoonBit provides `#visibility(change_to="readonly", ...)` to warn callers before a later visibility reduction. See [Attributes: Visibility Attribute](https://docs.moonbitlang.com/en/latest/language/attributes.html#visibility-attribute).

The local compiler used for this audit is `moonc v0.10.4+2cc641edf (2026-07-15)`, matching the documentation generation currently shown as v0.10.4.

## Decision rule

Keep `pub(all)` only if all of the following are true:

1. A normal external caller, not only a test, must construct the value.
2. Every externally representable value is valid; construction does not bypass validation or normalization.
3. The value does not carry package-owned lifecycle state, callbacks, mutable storage, parser provenance, or resource ownership.
4. Direct representation access is intended to remain a compatibility commitment.
5. A constructor or factory would add ceremony without preserving any useful boundary.

If callers only need to inspect or pattern-match a returned value, `pub` is sufficient. If callers need to create a struct, prefer `pub` plus a constructor or factory. If callers need to select among a small set of input modes and every variant is valid, `pub(all) enum` is appropriate.

## Highest-risk findings

### P0: `RunOptions` can bypass its own validation

`RunOptions::RunOptions` rejects non-positive `max_steps`, `node_timeout_ms`, and `cleanup_timeout_ms`, but `pub(all) struct RunOptions` allows an external package to construct the same invalid states with a struct literal. This directly defeats the package's validation boundary. Change the type to `pub struct RunOptions` and retain the existing validating constructor.

Source: [`runtime_types.mbt`](../../mbt/package/moon-agent-graph/src/core/runtime_types.mbt).

### P0: runtime-owned graph contexts are forgeable with struct literals

`NodeContext` and `CodingAgentOpenContext` contain run identifiers, task groups, event sinks, resource stores, workspace permissions, and environment state. These values describe runtime ownership, so external callers should not freely combine their fields with struct literals. Both types were changed to `pub`: `NodeContext` retains its existing constructor, while `CodingAgentOpenContext` now has a canonical constructor.

Sources: [`model.mbt`](../../mbt/package/moon-agent-graph/src/core/model.mbt) and [`coding_agent_contract.mbt`](../../mbt/package/moon-agent-graph/src/core/coding_agent_contract.mbt).

### P1: `admiral.Context` can bypass normalization with a struct literal

`Context` combines flags, values, value sources, configuration, and nested subcommands. A `pub(all)` struct literal bypasses the existing constructor's conversion to persistent maps and readonly arrays. The type was changed to `pub`, while `Context::Context`, which is used by documentation examples and external command tests, remains the canonical construction path.

Source: [`types.mbt`](../../mbt/package/admiral/src/types.mbt).

### P1: SDK protocol outputs are exposed as caller-constructible inputs

Codex and OpenCode events, items, completed turns, usage records, and SDK errors are produced by JSON decoding or process execution. Callers need to inspect and pattern-match them, but normal SDK use does not require constructing them. Their current `pub(all)` declarations turn protocol output shapes into a stronger public compatibility commitment and make black-box tests able to fabricate states that the decoder may never emit. Convert them to readonly `pub`; use decoder fixtures or white-box tests for malformed and impossible protocol states.

Representative sources: [`codex-sdk/events.mbt`](../../mbt/package/codex-sdk/src/events.mbt), [`codex-sdk/items.mbt`](../../mbt/package/codex-sdk/src/items.mbt), and [`opencode-sdk/events.mbt`](../../mbt/package/opencode-sdk/src/events.mbt).

## Module inventory

| Module                          |   Total | Keep `pub(all)` | Existing construction path | Add construction path | Readonly only |
| ------------------------------- | ------: | --------------: | -------------------------: | --------------------: | ------------: |
| `totto2727/any-collection`      |       2 |               0 |                          2 |                     0 |             0 |
| `totto2727/agent-cli-sdk`       |       4 |               0 |                          1 |                     0 |             3 |
| `totto2727/admiral`             |       5 |               0 |                          3 |                     1 |             1 |
| `totto2727/codex-sdk`           |      40 |               7 |                          3 |                     0 |            30 |
| `totto2727/lens`                |       8 |               1 |                          0 |                     0 |             7 |
| `totto2727/moon-agent-graph`    |      50 |               7 |                         10 |                    15 |            18 |
| `totto2727/opencode-sdk`        |      16 |               3 |                          2 |                     0 |            11 |
| `totto2727/opencode-server-sdk` |       1 |               0 |                          0 |                     0 |             1 |
| **Total**                       | **126** |          **18** |                     **21** |                **16** |        **71** |

### `totto2727/any-collection`

- Direct access to each wrapper's `map` field is an intentional exception accepted for implementation simplicity. The README, tests, and external example use underlying operations such as `contains`, `remove`, `length`, and `is_empty`. The field remains public, including direct mutation of the referenced `Map` in `AnyMutableMap`.
- Change `AnyMutableMap` to `pub` and retain its existing constructor. A readonly `pub struct` still exposes its non-private fields through dot syntax, so `pub(all)` is not required to invoke the accepted underlying Map operations.
- Change `AnyImmutableHashMap` to `pub` and retain its existing entry-based constructor. No additional `from_hash_map` constructor is required: callers that need to rewrap the result of a persistent `HashMap` operation can pass its entries through the existing constructor, even if that path is less convenient than a struct literal.

### `totto2727/agent-cli-sdk`

- Change to `pub` and retain the existing constructor: `Invocation`.
- Change to readonly `pub`: `JsonLine`, `RunResult`, `AgentCliError`.
- `JsonLine` and `RunResult` are process outputs; `AgentCliError` is raised by the protocol reader.

### `totto2727/admiral`

- Change to `pub` and retain the existing constructors or factories: `CommandDef` through `command`, `CliApp` through `cli`, and `Context` through `Context::Context`.
- Change to readonly `pub`: `OptionType`.
- Change to `pub` and add a small public constructor or helper for the callback boundary: `ConfigLoadFailure`. External `load_config` implementations need a supported way to raise this error, but they do not need unrestricted access to every future variant.

### `totto2727/codex-sdk`

- Keep `pub(all)` because callers intentionally construct these input enums: `CodexConfigValue`, `ApprovalMode`, `SandboxMode`, `ModelReasoningEffort`, `WebSearchMode`, `UserInput`, `Input`.
- Change to `pub` and retain the existing constructors: `CodexOptions`, `ThreadOptions`, `TurnOptions`.
- Change to readonly `pub`: `Turn`, `ThreadStartedEvent`, `TurnStartedEvent`, `Usage`, `TurnCompletedEvent`, `ThreadError`, `TurnFailedEvent`, `ItemStartedEvent`, `ItemUpdatedEvent`, `ItemCompletedEvent`, `ThreadErrorEvent`, `ThreadEvent`, `CommandExecutionStatus`, `CommandExecutionItem`, `PatchChangeKind`, `FileUpdateChange`, `PatchApplyStatus`, `FileChangeItem`, `McpToolCallStatus`, `McpToolCallResult`, `McpToolCallError`, `McpToolCallItem`, `AgentMessageItem`, `ReasoningItem`, `WebSearchItem`, `ErrorItem`, `TodoItem`, `TodoListItem`, `ThreadItem`, `CodexSdkError`.
- The 30 readonly candidates are all returned or raised by the SDK. Direct construction observed in tests is not a production API requirement.

### `totto2727/lens`

- Keep `pub(all)` because callers intentionally select the encoding mode: `NullishEncodeMode`.
- Change to readonly `pub`: `JsonKind`, `IssueCode`, `Issue`, `LensError`, `JsonBuildIssueCode`, `JsonBuildIssue`, `JsonBuildError`.
- These seven types describe failures produced by lens lookup, decoding, or building. Pattern matching remains available with `pub`; external construction is not required.

### `totto2727/moon-agent-graph`

- Keep `pub(all)` for caller-selected input enums whose complete variant sets are intentional: `Route`, `NodeKind`, `ArtifactKind`, `CodingAgentStatus`, `ApprovalPolicy`, `NetworkPolicy`, `ResourceScope`.
- Change to `pub` and retain existing constructors or factories: `EventSink`, `NodeContext`, `Node`, `DeclaredRouteMetadata`, `DeclaredRoute`, `RouterMetadata`, `Router`, `RunOptions`, `CodexAgentOptions`, `OpenCodeAgentOptions`.
- Change to `pub` and add constructors or narrowly scoped factories: `NodeMetadata`, `Artifact`, `NodeOutput`, `NodeCompletion`, `GraphEvent`, `Reducer`, `WorkspaceRef`, `CodingAgentRequest`, `CodingAgentResponse`, `CodingAgentOpenContext`, `CodingAgent`, `CodingAgentNodeSpec`, `LlmNodeSpec`, `WorkflowState`, `WorkflowPatch`.
- Change to readonly `pub`: `GraphBuildError`, `GraphValidationError`, `RunFailure`, `GraphRuntimeError`, `CompiledNodeSnapshot`, `CompiledGraphSnapshot`, `IdError`, `ResourceStoreError`, `RunConfigurationError`, `RunResult`, `CodexAdapterError`, `OpenCodeAdapterError`, `ScriptedNodeCall`, `ScriptedRouterCall`, `RecordingReducerCall`, `FakeCodingAgentOpenCall`, `FakeCodingAgentRequestCall`, `NativeTestHelperError`.
- `GraphEvent` itself is readonly; selected run and resource-lifecycle events are exposed through narrowly scoped factories instead of exposing every variant constructor.
- Recorded call structs under `testing` are accessor outputs. Tests need to read them, not construct or mutate them.
- `WorkflowState` and `WorkflowPatch` live in E2E support and are directly constructed by tests. Replace those literals with explicit E2E factories; do not let test convenience determine production visibility.

### `totto2727/opencode-sdk`

- Keep `pub(all)` because callers intentionally construct these input enums: `OpenCodeConfigValue`, `UserInput`, `Input`.
- Change to `pub` and retain the existing constructors: `OpenCodeOptions`, `ThreadOptions`.
- Change to readonly `pub`: `Turn`, `TextEvent`, `ReasoningEvent`, `ToolUseStatus`, `ToolUseEvent`, `StepStartEvent`, `Usage`, `StepFinishEvent`, `ThreadErrorEvent`, `ThreadEvent`, `OpenCodeSdkError`.
- Events and errors are decoder or process outputs; black-box tests should exercise decoding rather than require raw construction.

### `totto2727/opencode-server-sdk`

- Change `ServerError` to readonly `pub`. It is raised by server startup, readiness parsing, process exit, and cleanup paths; callers only need to inspect it.

## Recommended implementation order

1. Close direct validation bypasses first: `RunOptions`, `Context`, `NodeContext`, and `CodingAgentOpenContext`.
2. Convert structs that already have constructors or factories: option structs, agent adapter options, map wrappers, graph route metadata, and node/router wrappers.
3. Add the 16 missing construction APIs, migrate production call sites to them, and then reduce visibility.
4. Convert protocol outputs, graph events/results/snapshots, diagnostic records, suberrors, and testing call records to readonly `pub`.
5. Move same-package invalid-state tests to `_wbtest.mbt`; use narrowly scoped factories in a testing package for cross-package tests.
6. For published modules, apply `#visibility(change_to="readonly", "Use the package constructor or factory.")` for one compatibility window before the actual breaking visibility change.

## Verification expected during implementation

This report does not recommend a large test expansion. For each module, the minimum sufficient verification is:

1. Run `vp run mbt:check` after the visibility and call-site migration.
2. Run the existing MoonBit tests affected by the changed module boundaries.
3. Compile one small external or black-box consumer that confirms readonly fields and enum pattern matching still work while raw construction fails.
4. For `RunOptions` and any new validating constructor, retain one focused invalid-input regression test.

The applied implementation was verified by recounting the 126 in-scope declarations, confirming that only the intended 18 input enums remain `pub(all)`, running `vp run mbt:check`, and running the existing MoonBit tests on both configured targets.
