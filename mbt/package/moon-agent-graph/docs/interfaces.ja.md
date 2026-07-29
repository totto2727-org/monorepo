# Moon Agent Graph Runtime Interfaces

## ステータスと規約

本ドキュメントは、ネイティブ非同期MVPのレビュー済み公開契約を定義するものです。

スニペットは、ネイティブ非同期MVPの実装済みかつ検証済みの公開契約を記録しています。

実装は現在のMoonBitの規約に従います：

- `moon.mod` と `moon.pkg` が設定フォーマットです。
- `preferred_target = "native"` と `supported_targets = "native"` は必須です。
- 公開識別子ラッパーは `Eq`、`Hash`、`Debug` を導出します。
- 同期バリデーションとルーティングは明示的な `raise` アノテーションを使用します。
- 非同期関数は暗黙的に raise します。
- ジェネリックなランタイム動作は型付き関数フィールドを使用します。
- 非ジェネリックなランタイムポリモーフィズムは `pub(open) trait` とトレイトオブジェクトを使用する場合があります。
- 公開コレクションは、コンパイル済み内部コレクションの可変エイリアスとして返されません。

## 識別子

```moonbit
pub struct NodeId(String) derive(Eq, Hash, Debug)
pub struct RunId(String) derive(Eq, Hash, Debug)
pub struct ResourceKey(String) derive(Eq, Hash, Debug)
pub struct CodingAgentId(String) derive(Eq, Hash, Debug)
pub struct SessionId(String) derive(Eq, Hash, Debug)
```

各識別子にはバリデーション付きコンストラクタまたはパーサがあります。

```moonbit
pub(all) suberror IdError {
  EmptyId(kind~ : String)
} derive(Debug)

pub fn NodeId::parse(value : String) -> NodeId raise IdError
pub fn NodeId::to_string(self : NodeId) -> String
```

他の識別子型にも同等のAPIが提供されます。

マップキー型は `Eq` と `Hash` の両方を導出します。

## Route

```moonbit
pub(all) enum Route {
  To(NodeId)
  End
  Fail(String)
} derive(Debug)
```

`Fail` は意図的なグラフドメインの失敗を表します。

予期しないルーターの失敗は raise され、ランタイムによってラップされます。

## ノードメタデータと出力

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

ノード出力には第2のイベントキューは含まれません。

ノードは必要なときにコンテキストを通じてライブイベントを発行し、ランタイムはそれ自体でライフサイクルイベントを発行します。

## イベントシンク

MVPのイベントシンクは同期式です。

これによりイベントの順序が決定論的に保たれ、ランタイムの各遷移の間に非同期処理が挿入されることを防ぎます。

```moonbit
pub(all) struct EventSink {
  emit : (GraphEvent) -> Unit raise
}

pub fn EventSink::EventSink(emit : (GraphEvent) -> Unit raise) -> EventSink
pub fn EventSink::discard() -> EventSink
pub fn EventSink::try_emit(self : EventSink, event : GraphEvent) -> Unit
```

外部の非同期テレメトリアダプタはイベントをバッファリングし、別に所有するタスクで排出することができます。

イベントシンクの失敗は、ベストエフォートの診断報告後、ランタイムによってキャッチされ無視されます。

## ノードコンテキスト

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

ランタイムは `deadline_ms` を、設定されている場合のノードタイムアウトヒント（ミリ秒）として提供します。ランタイムはこのフィールドを通じてタイムアウトを強制しません。

MVPにはカスタムキャンセレーショントークンはありません。

非同期ノードコードは、通常の非同期呼び出しと `moonbitlang/async` のタスク状態を通じてキャンセレーションを監視します。

キャッチオールループは、`@async.is_being_cancelled()` が真になった時点で停止しなければなりません。

## Node

MoonBitのトレイトは、グラフの `S` および `P` 固有のコールバックコンテナに使用する必要はありません。

```moonbit
pub(all) struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}
```

非同期コールバックは、ドメイン `suberror` または下位レベルのエラーを raise する場合があります。

ランタイムはそのエラーをキャッチし、ノードIDとステップでラップします。

```moonbit
pub fn[S, P] function_node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P]
```

## Router

MVPではノードごとに1つのルーターを許可します。

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

`declared_targets` には、`evaluate` が `Route::To` を通じて返す可能性のある全てのノードIDが含まれます。

コンパイル時には、宣言されたターゲットが出力先のバリデーションと到達可能性に使用されます。

実行時に、宣言されていないターゲットを返した場合、そのノードが存在していても契約違反となります。

ルーターは同期式であり、I/Oの実行、モデルの呼び出し、コマンドの実行、または状態の変更を行ってはいけません。

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

リデューサーは唯一のランタイム状態更新パスです。

リデューサーは同じ状態とパッチに対して決定論的でなければなりません。

グラフ固有のコードは、状態値が永続的なスタイルの値であるか、制御された可変フィールドを含むかを決定します。

コアランタイムは任意のジェネリック状態をクローンしません。

## グラフ定義

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

グラフの変更メソッドは、ローカルな重複を即座に拒否します。

クロスリファレンスと到達可能性の失敗は `compile` によって報告されます。

## コンパイル済みグラフ

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

コンパイルは定義マップとノードごとの配列を、分離されたプライベートストレージにコピーします。

クエリメソッドはそのストレージの可変エイリアスを公開しません。

## ランタイムオプションと結果

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

`max_steps` は正の数でなければなりません。

タイムアウト値は指定される場合、正の数でなければなりません。

```moonbit
pub(all) struct RunResult[S] {
  run_id : RunId
  final_state : S
  steps : Int
} derive(Debug)
```

`RunResult` は成功完了のみを表します。

失敗とキャンセルは raise されます。

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

`invoke` は実行ごとのリソースストアとネストされた `TaskGroup[Unit]` を作成します。

固定の `Unit` グループ結果は、ネイティブプロセスの所有権ハンドルをグラフ状態型から独立させつつ、ランタイムがグループ終了まで成功した `RunResult[S]` を呼び出し内部に保持できるようにします。

呼び出し元は、`invoke` を実行するタスクをキャンセルすることでキャンセレーションを制御します。

ランタイムは `RunStarted` の後、`RunCompleted`、`RunFailed`、`RunCancelled` のうち正確に1つを発行します。

キャンセルエラーは、クリーンアップとベストエフォートのイベント発行後に再 raise されます。

## ランタイムエラー

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

アダプタは独自の `suberror` 型を定義し、ランタイムがそれらを原因として保持できるようにします。

## グラフイベント

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

## LLMノード境界

統合パッケージはMoonLLMを狭いコールバックに適応させます。

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

コールバック境界により、パラレルなMoonLLMクライアント階層を発明することなく、決定論的なフェイクが可能になります。

構造化出力ノードは、MoonLLMのResponses APIが適切なインターフェースである場合、異なるリクエスト/レスポンスペアを使用する場合があります。

## コーディングエージェントのリクエストとレスポンス

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

キャンセルは、成功した `Cancelled` レスポンスではなく、raise されたタスクキャンセルエラーによって表現されます。

アダプタは、そのSDKが信頼できる変更セットを公開しない場合、空の `changed_files` 配列を返すことがあります。

## コーディングエージェントポリシー

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

環境とポリシーはセッションオープン時の設定です。現在のCodexおよびOpenCodeアダプタは、クライアント、スレッド、またはサーバーを作成する際にこれらのいくつかを適用するためです。

アダプタ固有のオプションはアダプタのコンストラクタに残ります。

## コーディングエージェントセッション

共通のセッションインターフェースは非ジェネリックであり、非同期トレイトオブジェクトを使用します。

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

ランタイムは、あるアダプタによって作成されたセッションを別のアダプタに渡すことはありません。

`close` はセッション境界でべき等であり、リソースストアはそれを最大でも1回だけ呼び出します。

実行中のセッションは、タスクキャンセルに応答して、非同期呼び出しが終了する前に、所有するプロセス作業を終了またはキャンセルします。

## リソーススコープとストア

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

MVPストアは意図的に、一般的なコーディングエージェントセッションインターフェースに特化しています。

異種の任意リソースコンテナは、MoonBitが取得のための具体的な型付きユースケースを持つまで延期されます。

実行スコープのセッションは、1回の呼び出し内でリソースキーによって再利用されます。

ノードスコープのセッションは `owner` を必要とし、そのノードの試行後にクローズされます。実行スコープのセッションは所有者を省略し、キーによって再利用されます。

オープン失敗はストアに挿入されることはありません。

リソースは取得順序の逆順でクローズされます。

## コーディングエージェントノード

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

## Codexアダプタ

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

アダプタは、コンテキスト環境、ワークスペースルート、追加の書き込み可能ルート、承認、ネットワーク、および指定されたオプションを、固定されたCodex SDKにマッピングします。スレッドの最終レスポンスを `summary` として、SDKスレッドIDを `continuation_id` として、検出された完了パッチパスを `changed_files` として返します。アーティファクトと生の出力は返しません。セッションをクローズすると、以降の実行は `CodexAdapterError::SessionClosed` をraiseします。

## OpenCodeアダプタ

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

アダプタは、オープンコンテキストのタスクグループと、呼び出し元のエントリがアダプタのエントリを上書きするマージされた環境を使用して `@opencode_sdk.create_opencode_server` を起動します。`POST /session` でOpenCodeセッションを作成し、セッションタイトルにワークスペースルートを表現し、各指示を `POST /session/{id}/message` を通じて送信します。コンテキストファイルパスはテキストとして含まれ、添付なしと明示的にマークされます。成功したレスポンスは、OpenCodeセッションIDを `continuation_id` として保持し、テキスト部分をオプションの `summary` に結合し、生のレスポンスJSONを保持し、空の `changed_files` とアーティファクトを返します。サーバーURLは非公開のままです。セッションクローズは明示的にサーバーをクローズします。不正なレスポンス、メッセージエラー、およびクローズ後の実行は `OpenCodeAdapterError` をraiseします。

## テストフィクスチャ

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

フィクスチャのアクセサはスナップショットを返すため、テストはその履歴を変更できません。

## 確定済みMVP設計判断

1. 実行はネイティブのみで非同期です。
2. グラフ実行は逐次です。
3. 循環は許可され、`max_steps` によって制限されます。
4. 各ノードには正確に1つのルーターがあります。
5. ルーターの出力先は宣言され、コンパイル時に検証されます。
6. 状態は呼び出しローカルであり、リデューサーを通じてのみ更新されます。
7. キャンセルはタスクキャンセルを使用します。
8. 非同期クリーンアップは明示的で、キャンセルから保護され、タイムアウトで制限されます。
9. リソーススコープは各コーディングエージェントノードの仕様によって選択されます。
10. CodexとOpenCodeは、1つのセッション契約の背後にある別個のアダプタです。
11. 並列ノード、チェックポイント、永続状態、およびアプリケーションスコープのリソースは延期されました。

## 参考資料

- [MoonBit async programming](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBit error handling](https://docs.moonbitlang.com/en/latest/language/error-handling.html)
- [MoonBit methods and traits](https://docs.moonbitlang.com/en/latest/language/methods.html)
- [MoonBit deriving traits](https://docs.moonbitlang.com/en/latest/language/derive.html)
- [MoonBit module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)