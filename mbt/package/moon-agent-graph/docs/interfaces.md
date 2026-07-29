# Moon Agent Graph Runtime Interfaces

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
pub struct CodingAgentId(String) derive(Eq, Hash, Debug)
pub struct SessionId(String) derive(Eq, Hash, Debug)
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
pub(all) enum ArtifactKind {
  File
  Directory
  Text
  Json
  CommandLog
  Custom(String)
} derive(Debug, Eq)

pub(all) struct Artifact {
  kind : ArtifactKind
  name : String
  uri : String?
  metadata : Json?
} derive(Debug)

pub(all) struct NodeOutput[P] {
  patch : P?
  value : Json?
  artifacts : Array[Artifact]
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
  resources : RuntimeResourceStore
}

pub fn NodeContext::NodeContext(
  run_id : RunId,
  node_id : NodeId,
  step : Int,
  task_group : @async.TaskGroup[Unit],
  events? : EventSink = EventSink::discard(),
  resources? : RuntimeResourceStore = RuntimeResourceStore(),
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
pub fn[S, P] function_node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P]
```

## Router

The MVP permits one router per node.

```moonbit
pub(all) struct Router[S] {
  declared_targets : ReadOnlyArray[NodeId]
  evaluate : (S, NodeCompletion) -> Route raise
}

pub(all) struct NodeCompletion {
  node_id : NodeId
  value : Json?
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)
```

`declared_targets` contains every node ID that `evaluate` may return through `Route::To`.

Compilation uses declared targets for destination validation and reachability.

At runtime, returning an undeclared target is a contract error even if that node exists.

Routers are synchronous and must not perform I/O, invoke models, execute commands, or mutate state.

```moonbit
pub fn[S] router(
  declared_targets : ReadOnlyArray[NodeId],
  evaluate : (S, NodeCompletion) -> Route raise,
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
```

Compilation copies definition maps and per-node arrays into detached private storage.

Query methods do not expose mutable aliases of that storage.

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
  cleanup : Array[Error]
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

The integration package adapts MoonLLM to a narrow callback.

```moonbit
pub(all) struct LlmNodeSpec[S, P] {
  build_request : (NodeContext, S) -> @moonllm.ChatRequest raise
  invoke : async (@moonllm.ChatRequest) -> @moonllm.ChatResponse
  decode_response : (S, @moonllm.ChatResponse) -> NodeOutput[P] raise
}

pub fn[S, P] llm_node(
  id : NodeId,
  metadata : NodeMetadata,
  spec : LlmNodeSpec[S, P],
) -> Node[S, P]
```

The callback boundary makes deterministic fakes possible without inventing a parallel MoonLLM client hierarchy.

Structured-output nodes may use a different request/response pair when MoonLLM's Responses API is the correct surface.

## Coding-Agent Request and Response

```moonbit
pub(all) struct WorkspaceRef {
  root : @path.Path
  additional_writable_roots : Array[@path.Path]
} derive(Debug, Eq)

pub(all) struct CodingAgentRequest {
  instruction : String
  context_files : Array[@path.Path]
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
  changed_files : Array[@path.Path]
  artifacts : Array[Artifact]
  raw_output : Json?
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
  environment : Map[String, String]
  events : EventSink
} derive(Debug)
```

Environment and policy are session-open settings because the current Codex and OpenCode adapters apply several of them when creating the client, thread, or server.

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

`close` is idempotent at the session boundary, and the resource store invokes it at most once.

An executing session responds to task cancellation by terminating or cancelling its owned process work before the async call exits.

## Resource Scope and Store

```moonbit
pub(all) enum ResourceScope {
  Node
  Run
} derive(Debug, Eq)

pub struct RuntimeResourceStore

pub fn RuntimeResourceStore::RuntimeResourceStore() -> RuntimeResourceStore

pub async fn RuntimeResourceStore::acquire_agent_session(
  self : RuntimeResourceStore,
  key : ResourceKey,
  scope : ResourceScope,
  open : async () -> &CodingAgentSession,
  owner? : NodeId,
) -> &CodingAgentSession

pub async fn RuntimeResourceStore::release_node(
  self : RuntimeResourceStore,
  node_id : NodeId,
) -> Unit

pub async fn RuntimeResourceStore::close_all(
  self : RuntimeResourceStore,
) -> Unit

pub async fn RuntimeResourceStore::finalize(
  self : RuntimeResourceStore,
  timeout_ms : Int,
) -> Unit
```

```moonbit
pub(all) suberror ResourceStoreError {
  NodeOwnerRequired(ResourceKey)
  InvalidCleanupTimeout(Int)
  CleanupTimedOut(Int)
  CloseFailed(errors~ : Array[Error])
} derive(Debug)
```

The MVP store is deliberately specialized to the common coding-agent session interface.

A heterogeneous arbitrary-resource container is deferred until MoonBit has a concrete typed use case for retrieval.

Run-scoped sessions are reused by resource key inside one invocation.

Node-scoped sessions require `owner` and close after that node attempt; run-scoped sessions omit the owner and are reused by key.

Open failures are never inserted into the store.

Resources close in reverse acquisition order.

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

The adapter maps context environment, workspace root, additional writable roots, approval, network, and supplied options to the pinned Codex SDK. It returns the thread final response as `summary`, the SDK thread ID as `continuation_id`, discovered completed patch paths as `changed_files`, no artifacts, and no raw output. Closing a session makes later execution raise `CodexAdapterError::SessionClosed`.

## OpenCode Adapter

```moonbit
pub(all) struct OpenCodeAgentOptions {
  server_options : @opencode_sdk.ServerOptions
  command : String
  extra_env : Map[String, String]
  request_timeout_ms : Int
}

pub fn OpenCodeAgentOptions::OpenCodeAgentOptions(
  server_options? : @opencode_sdk.ServerOptions = @opencode_sdk.ServerOptions(),
  command? : String = "opencode",
  extra_env? : Map[String, String] = Map([]),
  request_timeout_ms? : Int = 180000,
) -> OpenCodeAgentOptions

pub(all) suberror OpenCodeAdapterError {
  InvalidSessionResponse
  InvalidMessageResponse
  MessageFailed(String)
  SessionClosed
} derive(Debug)

pub fn opencode_agent(
  id : CodingAgentId,
  options : OpenCodeAgentOptions,
) -> CodingAgent
```

The adapter starts `@opencode_sdk.create_opencode_server` with the open context task group and a merged environment where caller entries override adapter entries. It creates an OpenCode session with `POST /session`, represents the workspace root in the session title, and sends each instruction through `POST /session/{id}/message`. Context file paths are included as text and explicitly marked as not attached. Successful responses preserve the OpenCode session ID as `continuation_id`, concatenate text parts into an optional `summary`, preserve the raw response JSON, and return empty `changed_files` and artifacts. The server URL remains private. Session close explicitly closes the server; malformed responses, message errors, and execution after close raise `OpenCodeAdapterError`.

## Testing Fixtures

```moonbit
pub(all) struct FakeCodingAgentOpenCall {
  context : CodingAgentOpenContext
}

pub(all) struct FakeCodingAgentRequestCall {
  session_id : SessionId?
  request : CodingAgentRequest
}

pub struct FakeCodingAgentSession
pub fn FakeCodingAgentSession::requests(self : FakeCodingAgentSession) -> ReadOnlyArray[FakeCodingAgentRequestCall]
pub fn FakeCodingAgentSession::is_closed(self : FakeCodingAgentSession) -> Bool

pub struct FakeCodingAgent
pub fn fake_coding_agent(
  response : CodingAgentResponse,
  session_id? : SessionId,
  open_error? : Error,
  execute_error? : Error,
) -> FakeCodingAgent
pub fn FakeCodingAgent::agent(self : FakeCodingAgent) -> CodingAgent
pub fn FakeCodingAgent::open_calls(self : FakeCodingAgent) -> ReadOnlyArray[FakeCodingAgentOpenCall]
pub fn FakeCodingAgent::request_calls(self : FakeCodingAgent) -> ReadOnlyArray[FakeCodingAgentRequestCall]
pub fn FakeCodingAgent::session_ids(self : FakeCodingAgent) -> ReadOnlyArray[SessionId?]
pub fn FakeCodingAgent::close_order(self : FakeCodingAgent) -> ReadOnlyArray[SessionId?]

pub struct FakeMoonLlmInvoke
pub fn fake_moonllm_invoke(
  response : @moonllm.ChatResponse,
  error? : Error,
) -> FakeMoonLlmInvoke
pub fn FakeMoonLlmInvoke::callback(
  self : FakeMoonLlmInvoke,
) -> async (@moonllm.ChatRequest) -> @moonllm.ChatResponse
pub fn FakeMoonLlmInvoke::requests(
  self : FakeMoonLlmInvoke,
) -> ReadOnlyArray[@moonllm.ChatRequest]

pub(all) struct ScriptedNodeCall[S] {
  context : NodeContext
  state : S
}

pub struct ScriptedNode[S, P]
pub fn[S, P] scripted_node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> ScriptedNode[S, P]
pub fn[S, P] ScriptedNode::node(self : ScriptedNode[S, P]) -> Node[S, P]
pub fn[S, P] ScriptedNode::calls(self : ScriptedNode[S, P]) -> ReadOnlyArray[ScriptedNodeCall[S]]

pub(all) struct ScriptedRouterCall[S] {
  state : S
  completion : NodeCompletion
}

pub struct ScriptedRouter[S]
pub fn[S] scripted_router(
  declared_targets : ReadOnlyArray[NodeId],
  evaluate : (S, NodeCompletion) -> Route raise,
) -> ScriptedRouter[S]
pub fn[S] ScriptedRouter::router(self : ScriptedRouter[S]) -> Router[S]
pub fn[S] ScriptedRouter::calls(self : ScriptedRouter[S]) -> ReadOnlyArray[ScriptedRouterCall[S]]

pub(all) struct RecordingReducerCall[S, P] {
  state : S
  patch : P
}

pub struct RecordingReducer[S, P]
pub fn[S, P] recording_reducer(apply : (S, P) -> S raise) -> RecordingReducer[S, P]
pub fn[S, P] RecordingReducer::reducer(self : RecordingReducer[S, P]) -> Reducer[S, P]
pub fn[S, P] RecordingReducer::calls(self : RecordingReducer[S, P]) -> ReadOnlyArray[RecordingReducerCall[S, P]]

pub struct RecordingEventSink
pub fn recording_event_sink() -> RecordingEventSink
pub fn RecordingEventSink::event_sink(self : RecordingEventSink) -> EventSink
pub fn RecordingEventSink::events(self : RecordingEventSink) -> ReadOnlyArray[GraphEvent]

pub(all) suberror NativeTestHelperError {
  EventuallyTimedOut(timeout_ms~ : Int)
  InvalidEventuallyInterval(timeout_ms~ : Int, poll_ms~ : Int)
} derive(Debug)

pub struct TemporaryWorkspace
pub fn TemporaryWorkspace::root(self : TemporaryWorkspace) -> @path.Path
pub async fn temporary_workspace(
  prefix? : String = "moon-agent-graph-test-",
) -> TemporaryWorkspace
pub async fn TemporaryWorkspace::close(self : TemporaryWorkspace) -> Unit
pub async fn eventually(
  timeout_ms : Int,
  predicate : async () -> Bool,
  poll_ms? : Int = 10,
) -> Unit
pub async fn process_is_running(pid : Int) -> Bool
pub async fn localhost_port_is_open(
  port : Int,
  timeout_ms? : Int = 250,
) -> Bool
```

The fixture accessors return snapshots so tests cannot mutate their histories.

## Fixed MVP Decisions

1. Execution is native-only and async.
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
