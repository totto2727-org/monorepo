# Workgraph Runtime Interfaces

## Status and Conventions

This document defines the reviewed public contract for the native asynchronous MVP.

The snippets record the implemented and verified public contract for the native asynchronous MVP.

The implementation uses current MoonBit conventions:

- `moon.mod` and `moon.pkg` are the configuration formats.
- `preferred_target = "native"` and `supported_targets = "native"` are mandatory.
- Public identifier wrappers derive `Eq`, `Hash`, and `Debug`.
- Synchronous validation and routing use explicit `raise` annotations.
- Async functions raise implicitly.
- Generic runtime behaviors use typed function fields.
- Non-generic runtime polymorphism may use `pub(open) trait` and trait objects.
- Public collections are not returned as mutable aliases of compiled internal collections.

## Identifiers

```moonbit
pub struct NodeId(String) derive(Eq, Hash, Debug)
pub struct RunId(String) derive(Eq, Hash, Debug)
pub struct ResourceKey(String) derive(Eq, Hash, Debug)
```

Each identifier has a validating constructor or parser.

```moonbit
pub(all) suberror IdError {
  EmptyId(kind~ : String)
} derive(Debug)

pub fn NodeId::parse(value : String) -> NodeId raise IdError
pub fn NodeId::to_string(self : NodeId) -> String
```

Equivalent APIs are provided for the other identifier types.

Map key types derive both `Eq` and `Hash`.

## Route

```moonbit
pub(all) enum Route {
  To(NodeId)
  End
  Fail(String)
} derive(Debug)
```

`Fail` represents an intentional graph-domain failure.

Unexpected router failures are raised and wrapped by the runtime.

## Node Metadata and Output

```moonbit
pub(all) enum NodeKind {
  Function
  Llm
  CodingAgent
  Custom(String)
} derive(Debug, Eq)

pub(all) struct NodeMetadata {
  name : String
  description : String?
  kind : NodeKind
  tags : ReadOnlyArray[String]
} derive(Debug)
```

```moonbit
pub(all) struct NodeOutput[P] {
  patch : P?
  value : Json?
} derive(Debug)
```

Node output does not contain a second event queue.

Nodes emit live events through their context when needed, while the runtime emits lifecycle events itself.

## Event Sink

The MVP event sink is synchronous.

This keeps event ordering deterministic and avoids introducing an async operation between every runtime transition.

```moonbit
pub(all) struct EventSink {
  emit : (GraphEvent) -> Unit raise
}

pub fn EventSink::EventSink(emit : (GraphEvent) -> Unit raise) -> EventSink
pub fn EventSink::discard() -> EventSink
pub fn EventSink::try_emit(self : EventSink, event : GraphEvent) -> Unit
```

An external asynchronous telemetry adapter may buffer events and drain them in a separately owned task.

An event sink failure is caught and ignored by the runtime after best-effort diagnostic reporting.

## Node Context

```moonbit
pub(all) struct NodeContext {
  run_id : RunId
  node_id : NodeId
  step : Int
  deadline_ms : Int64?
  task_group : @async.TaskGroup[Unit]
  events : EventSink
  resources : ResourceStore
}

pub fn NodeContext::NodeContext(
  run_id : RunId,
  node_id : NodeId,
  step : Int,
  task_group : @async.TaskGroup[Unit],
  events? : EventSink = EventSink::discard(),
  resources? : ResourceStore = ResourceStore(),
  deadline_ms? : Int64,
) -> NodeContext
```

The runtime supplies `deadline_ms` as the configured node-timeout hint in milliseconds when one exists; it does not enforce the timeout through this field.

There is no custom cancellation token in the MVP.

Async node code observes cancellation through normal async calls and `moonbitlang/async` task state.

Catch-all loops must stop when `@async.is_being_cancelled()` is true.

## Node

MoonBit traits do not need to be used for the graph's `S` and `P`-specific callback container.

```moonbit
pub(all) struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}
```

The async callback may raise a domain `suberror` or a lower-level error.

The runtime catches and wraps that error with the node ID and step.

```moonbit
pub fn[S, P] Node::Node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P]
```

## Router

The MVP permits one router per node.

```moonbit
pub(all) struct DeclaredRouteMetadata {
  label : String?
}

pub(all) struct DeclaredRoute {
  target : NodeId
  metadata : DeclaredRouteMetadata
}

pub(all) struct RouterMetadata {
  description : String?
}

pub(all) struct Router[S] {
  metadata : RouterMetadata
  declared_routes : ReadOnlyArray[DeclaredRoute]
  evaluate : (S, NodeCompletion) -> Route raise
}

pub(all) struct NodeCompletion {
  node_id : NodeId
  value : Json?
} derive(Debug)
```

`declared_routes` contains every node ID that `evaluate` may return through `Route::To`, together with optional display metadata.

Compilation uses declared targets for destination validation and reachability.

At runtime, returning an undeclared target is a contract error even if that node exists.

Routers are synchronous and must not perform I/O, invoke models, execute commands, or mutate state.

`RouterMetadata.description` and `DeclaredRouteMetadata.label` are optional presentation hints for inspection tools. They do not affect route evaluation.

```moonbit
pub fn[S] router(
  declared_routes : ReadOnlyArray[DeclaredRoute],
  evaluate : (S, NodeCompletion) -> Route raise,
  metadata? : RouterMetadata = RouterMetadata::RouterMetadata(),
) -> Router[S]
```

## Reducer

```moonbit
pub(all) struct Reducer[S, P] {
  apply : (S, P) -> S raise
}
```

The reducer is the only runtime state-update path.

The reducer must be deterministic for the same state and patch.

Graph-specific code decides whether state values are persistent-style values or contain controlled mutable fields.

The core runtime does not clone arbitrary generic state.

## Graph Definition

```moonbit
pub struct GraphDefinition[S, P]

pub fn[S, P] GraphDefinition::GraphDefinition(
  reducer : Reducer[S, P],
) -> GraphDefinition[S, P]

pub fn[S, P] GraphDefinition::add_node(
  self : GraphDefinition[S, P],
  node : Node[S, P],
) -> Unit raise GraphBuildError

pub fn[S, P] GraphDefinition::set_router(
  self : GraphDefinition[S, P],
  from : NodeId,
  router : Router[S],
) -> Unit raise GraphBuildError

pub fn[S, P] GraphDefinition::set_entry(
  self : GraphDefinition[S, P],
  entry : NodeId,
) -> Unit raise GraphBuildError

pub fn[S, P] GraphDefinition::compile(
  self : GraphDefinition[S, P],
) -> CompiledGraph[S, P] raise GraphValidationError
```

```moonbit
pub(all) suberror GraphBuildError {
  DuplicateNode(NodeId)
  DuplicateRouter(NodeId)
  InvalidId(String)
} derive(Debug)

pub(all) suberror GraphValidationError {
  MissingEntry
  UnknownEntry(NodeId)
  MissingRouter(NodeId)
  UnknownRouterSource(NodeId)
  UnknownDestination(from~ : NodeId, to~ : NodeId)
  UnreachableNode(NodeId)
} derive(Debug)
```

Graph mutation methods reject local duplicates immediately.

Cross-reference and reachability failures are reported by `compile`.

## Compiled Graph

```moonbit
pub struct CompiledGraph[S, P]

pub fn[S, P] CompiledGraph::entry(
  self : CompiledGraph[S, P],
) -> NodeId

pub fn[S, P] CompiledGraph::get_node(
  self : CompiledGraph[S, P],
  id : NodeId,
) -> Node[S, P] raise GraphRuntimeError

pub fn[S, P] CompiledGraph::get_router(
  self : CompiledGraph[S, P],
  id : NodeId,
) -> Router[S] raise GraphRuntimeError

pub(all) struct CompiledNodeSnapshot {
  id : NodeId
  metadata : NodeMetadata
  router_metadata : RouterMetadata
  declared_routes : ReadOnlyArray[DeclaredRoute]
}

pub(all) struct CompiledGraphSnapshot {
  entry : NodeId
  nodes : ReadOnlyArray[CompiledNodeSnapshot]
}

pub fn[S, P] CompiledGraph::snapshot(
  self : CompiledGraph[S, P],
) -> CompiledGraphSnapshot
```

Compilation stores immutable node and router values in private persistent hash maps. Builder mutations after compilation cannot alter the compiled structure.

Query methods do not expose mutable aliases of that storage.

`snapshot` returns the deterministic callback-free structure used by inspection tools.

## Visualization

The optional `totto2727/workgraph-visualization` package renders a compiled graph as Mermaid without exposing runtime callbacks.

```moonbit
pub fn[S, P] to_mermaid(graph : CompiledGraph[S, P]) -> String
```

The renderer uses node descriptions, router descriptions, and declared route labels from `core` metadata. It does not infer runtime-only conditions or `End` and `Fail` outcomes.

## Runtime Options and Result

```moonbit
pub(all) struct RunOptions {
  max_steps : Int
  node_timeout_ms : Int?
  cleanup_timeout_ms : Int
}

pub fn RunOptions::RunOptions(
  max_steps? : Int = 100,
  node_timeout_ms? : Int,
  cleanup_timeout_ms? : Int = 5000,
) -> RunOptions raise RunConfigurationError
```

```moonbit
pub(all) suberror RunConfigurationError {
  MaxStepsMustBePositive(Int)
  NodeTimeoutMustBePositive(Int)
  CleanupTimeoutMustBePositive(Int)
} derive(Debug)
```

`max_steps` must be positive.

Timeout values must be positive when present.

```moonbit
pub(all) struct RunResult[S] {
  run_id : RunId
  final_state : S
  steps : Int
} derive(Debug)
```

A `RunResult` represents successful completion only.

Failures and cancellation are raised.

## Runtime

```moonbit
pub struct GraphRuntime[S, P] {
  graph : CompiledGraph[S, P]
  events : EventSink
}

pub fn[S, P] GraphRuntime::GraphRuntime(
  graph : CompiledGraph[S, P],
  events? : EventSink = EventSink::discard(),
) -> GraphRuntime[S, P]

pub fn[S, P] GraphRuntime::fresh_run_id(
  self : GraphRuntime[S, P],
) -> RunId

pub async fn[S, P] GraphRuntime::invoke(
  self : GraphRuntime[S, P],
  initial_state : S,
  options? : RunOptions = RunOptions(),
) -> RunResult[S]
```

`invoke` creates the per-run resource store and nested `TaskGroup[Unit]`.

The fixed `Unit` group result keeps the native process-ownership handle independent of graph state type while the runtime stores the successful `RunResult[S]` inside the invocation until the group exits.

The caller controls cancellation by cancelling the task that executes `invoke`.

The runtime emits exactly one of `RunCompleted`, `RunFailed`, or `RunCancelled` after `RunStarted`.

The cancellation error is re-raised after cleanup and best-effort event emission.

## Runtime Errors

```moonbit
pub(all) struct RunFailure {
  primary : Error
  cleanup : ReadOnlyArray[Error]
} derive(Debug)

pub(all) suberror GraphRuntimeError {
  NodeTimedOut(node_id~ : NodeId, step~ : Int, timeout_ms~ : Int)
  NodeFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  ReduceFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteContractViolated(from~ : NodeId, to~ : NodeId)
  StepLimitExceeded(limit~ : Int)
  ExplicitFailure(node_id~ : NodeId, message~ : String)
  ResourceCleanupFailed(failure~ : RunFailure)
  NodeNotFound(NodeId)
  RouterNotFound(NodeId)
} derive(Debug)
```

Adapters define their own `suberror` types and allow the runtime to preserve them as causes.

## Graph Events

```moonbit
pub(all) enum GraphEvent {
  RunStarted(RunId)
  RunCompleted(run_id~ : RunId, steps~ : Int)
  RunFailed(run_id~ : RunId, cause~ : Error)
  RunCancelled(RunId)
  NodeStarted(run_id~ : RunId, node_id~ : NodeId, step~ : Int)
  NodeCompleted(
    run_id~ : RunId,
    node_id~ : NodeId,
    step~ : Int,
    completion~ : NodeCompletion,
  )
  NodeFailed(
    run_id~ : RunId,
    node_id~ : NodeId,
    step~ : Int,
    cause~ : Error,
  )
  StateUpdated(run_id~ : RunId, node_id~ : NodeId, step~ : Int)
  RouteSelected(run_id~ : RunId, from~ : NodeId, route~ : Route)
  ResourceOpening(run_id~ : RunId, key~ : ResourceKey)
  ResourceOpened(run_id~ : RunId, key~ : ResourceKey)
  ResourceClosed(run_id~ : RunId, key~ : ResourceKey)
} derive(Debug)
```

## LLM Node Boundary

The integration package adapts `mizchi/llm` message, tool, provider, and result types to a provider-backed graph node.

```moonbit
pub(all) struct LlmRequest {
  messages : Array[@llm.Message]
  tools : Array[@llm.ToolDef]
}

pub struct LlmNodeSpec[S, P] {
  provider : @llm.BoxedProvider
  build_request : (NodeContext, S) -> LlmRequest raise
  decode_response : (S, @llm.CollectResult) -> NodeOutput[P] raise
}

pub fn[S, P] llm_node(
  id : NodeId,
  metadata : NodeMetadata,
  spec : LlmNodeSpec[S, P],
) -> Node[S, P]
```

The caller constructs any `mizchi/llm` provider, boxes it with the provider package's public adapter, and passes it to the specification. `workgraph-llm` invokes the provider and collects its stream, while the two callbacks retain only application-specific state-to-request and response-to-output mapping.

`mizchi/llm` stream errors are converted to `LlmNodeError::ProviderFailed` and remain graph node failures.

## Coding-Agent Request and Response

These interfaces belong to `workgraph-agent-cli`; core does not import them.

```moonbit
pub struct CodingAgentId(String) derive(Eq, Hash, Debug)
pub struct SessionId(String) derive(Eq, Hash, Debug)

pub(all) struct WorkspaceRef {
  root : @path.Path
  additional_writable_roots : ReadOnlyArray[@path.Path]
} derive(Debug, Eq)

pub(all) struct CodingAgentRequest {
  instruction : String
  context_files : ReadOnlyArray[@path.Path]
} derive(Debug, Eq)

pub(all) enum CodingAgentStatus {
  Succeeded
  Failed
  NeedsApproval
} derive(Debug, Eq)

pub(all) struct CodingAgentResponse {
  status : CodingAgentStatus
  summary : String?
  continuation_id : String?
  changed_files : ReadOnlyArray[@path.Path]
} derive(Debug)
```

Cancellation is represented by the raised task-cancellation error rather than a successful `Cancelled` response.

An adapter may return an empty `changed_files` array when its SDK does not expose a reliable change set.

## Coding-Agent Policy

```moonbit
pub(all) enum ApprovalPolicy {
  Never
  OnRequest
  OnFailure
  Untrusted
} derive(Debug, Eq)

pub(all) enum NetworkPolicy {
  Disabled
  Enabled
} derive(Debug, Eq)

pub(all) struct CodingAgentOpenContext {
  run_id : RunId
  task_group : @async.TaskGroup[Unit]
  workspace : WorkspaceRef
  approval : ApprovalPolicy
  network : NetworkPolicy
  environment : @immut_hashmap.HashMap[String, String]
  events : EventSink
} derive(Debug)
```

Environment and policy are session-open settings because the current Codex and OpenCode adapters apply supported values when creating their clients and threads.

Adapter-specific options remain in adapter constructors.

## Coding-Agent Session

The common session interface is non-generic and uses an async trait object.

```moonbit
pub(open) trait CodingAgentSession {
  fn id(Self) -> SessionId?
  async fn execute(Self, CodingAgentRequest) -> CodingAgentResponse
  async fn close(Self) -> Unit
}

pub(all) struct CodingAgent {
  id : CodingAgentId
  open : async (CodingAgentOpenContext) -> &CodingAgentSession
}
```

The runtime never passes a session created by one adapter into another adapter.

`close` is idempotent at the session boundary, and the coding-agent resource registers it as an ordinary cleanup callback that runs at most once.

An executing session responds to task cancellation by terminating or cancelling its owned process work before the async call exits.

## Resource Scope and Store

```moonbit
pub(all) enum ResourceScope {
  Node
  Run
} derive(Debug, Eq)

pub struct ResourceStore

pub fn ResourceStore::ResourceStore() -> ResourceStore

pub fn[T] ResourceStore::set(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
  value : T,
) -> Unit

pub fn[T] ResourceStore::get(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
) -> T? raise

pub fn[T] ResourceStore::remove(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
) -> Unit

pub async fn[T] ResourceStore::acquire_resource(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
  scope : ResourceScope,
  open : async () -> T,
  cleanup : async (T) -> Unit,
  owner? : NodeId,
) -> T

pub async fn ResourceStore::release_node(
  self : ResourceStore,
  node_id : NodeId,
) -> Unit

pub async fn ResourceStore::close_all(
  self : ResourceStore,
) -> Unit

pub async fn ResourceStore::finalize(
  self : ResourceStore,
  timeout_ms : Int,
) -> Unit
```

The store accepts any `@any.Anyable` value, including mutable process-local resources that cannot be represented in graph `Json` state. `set`, `get`, and `remove` manage plain values. `acquire_resource` adds the same optional Node- or Run-scoped lifecycle to any resource type.

```moonbit
pub(all) suberror ResourceStoreError {
  NodeOwnerRequired(ResourceKey)
  InvalidCleanupTimeout(Int)
  CleanupTimedOut(Int)
  CloseFailed(errors~ : ReadOnlyArray[Error])
} derive(Debug)
```

Run-scoped resources are reused through their typed reference inside one invocation.

Node-scoped resources require `owner` and run their registered cleanup after that node attempt; run-scoped resources omit the owner and remain until finalization.

Open failures are never inserted into the store.

Managed resources run cleanup in reverse acquisition order. A coding-agent process is stored as an ordinary typed resource and uses this same acquisition and cleanup path.

## Coding-Agent Node

```moonbit
pub(all) struct CodingAgentNodeSpec[S, P] {
  agent : CodingAgent
  resource_key : ResourceKey
  resource_scope : ResourceScope
  open_context : (NodeContext, S) -> CodingAgentOpenContext raise
  build_request : (NodeContext, S) -> CodingAgentRequest raise
  decode_response : (S, CodingAgentResponse) -> NodeOutput[P] raise
}

pub fn[S, P] coding_agent_node(
  id : NodeId,
  metadata : NodeMetadata,
  spec : CodingAgentNodeSpec[S, P],
) -> Node[S, P]
```

## Codex Adapter

```moonbit
pub(all) struct CodexAgentOptions {
  codex_path_override : @path.Path?
  base_url : String?
  api_key : String?
  config : @codex_sdk.CodexConfigObject?
  resume_thread_id : String?
  model : String?
  sandbox : @codex_sdk.SandboxMode?
  skip_git : Bool?
  reasoning : @codex_sdk.ModelReasoningEffort?
  web_search : @codex_sdk.WebSearchMode?
}

pub fn CodexAgentOptions::CodexAgentOptions(
  codex_path_override? : @path.Path,
  base_url? : String,
  api_key? : String,
  config? : @codex_sdk.CodexConfigObject,
  resume_thread_id? : String,
  model? : String,
  sandbox? : @codex_sdk.SandboxMode,
  skip_git? : Bool,
  reasoning? : @codex_sdk.ModelReasoningEffort,
  web_search? : @codex_sdk.WebSearchMode,
) -> CodexAgentOptions

pub(all) suberror CodexAdapterError {
  SessionClosed
} derive(Debug)

pub fn codex_agent(
  id : CodingAgentId,
  options : CodexAgentOptions,
) -> CodingAgent
```

The adapter maps context environment, workspace root, additional writable roots, approval, network, and supplied options to the pinned Codex SDK. It returns the thread final response as `summary`, the SDK thread ID as `continuation_id`, and discovered completed patch paths as `changed_files`. Closing a session makes later execution raise `CodexAdapterError::SessionClosed`.

## OpenCode Adapter

```moonbit
pub(all) struct OpenCodeAgentOptions {
  opencode_path_override : @path.Path?
  config : @opencode_sdk.OpenCodeConfigObject?
  resume_thread_id : String?
  model : String?
  agent : String?
  variant : String?
  title : String?
  thinking : Bool
  extra_env : Map[String, String]
}

pub fn OpenCodeAgentOptions::OpenCodeAgentOptions(
  opencode_path_override? : @path.Path,
  config? : @opencode_sdk.OpenCodeConfigObject,
  resume_thread_id? : String,
  model? : String,
  agent? : String,
  variant? : String,
  title? : String,
  thinking? : Bool = false,
  extra_env? : Map[String, String] = Map([]),
) -> OpenCodeAgentOptions

pub(all) suberror OpenCodeAdapterError {
  SessionClosed
} derive(Debug)

pub fn opencode_agent(
  id : CodingAgentId,
  options : OpenCodeAgentOptions,
) -> CodingAgent
```

The adapter uses `totto2727/opencode-sdk` as a CLI SDK and does not import the separately maintained `opencode-server-sdk`. It starts or resumes an SDK thread, runs each instruction through `opencode run --format json`, resolves relative context files against the workspace root, and forwards them as repeated CLI file inputs. The inherited process environment is retained, adapter entries are applied next, and caller context entries take precedence. Successful turns return final text as `summary`, the SDK thread ID as `continuation_id`, and an empty `changed_files` array because the current OpenCode event model exposes no reliable file-change set at this boundary. Each turn owns its subprocess; cancellation and concrete `OpenCodeSdkError` values propagate from the CLI SDK. Closing the logical session is idempotent and later execution raises `OpenCodeAdapterError::SessionClosed`.

## Fixed MVP Decisions

1. Core, LLM, and visualization execution supports native and JavaScript; coding-agent and CLI integrations are native-only.
2. Graph execution is sequential.
3. Cycles are allowed and bounded by `max_steps`.
4. Each node has exactly one router.
5. Router destinations are declared and compile-validated.
6. State is invocation-local and updated only through a reducer.
7. Cancellation uses task cancellation.
8. Async cleanup is explicit, cancellation-protected, and timeout-bounded.
9. Resource scope is selected by each coding-agent node specification.
10. Codex and OpenCode are separate adapters behind one session contract.
11. Parallel nodes, checkpointing, durable state, and application-scoped resources are deferred.

## References

- [MoonBit async programming](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBit error handling](https://docs.moonbitlang.com/en/latest/language/error-handling.html)
- [MoonBit methods and traits](https://docs.moonbitlang.com/en/latest/language/methods.html)
- [MoonBit deriving traits](https://docs.moonbitlang.com/en/latest/language/derive.html)
- [MoonBit module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
