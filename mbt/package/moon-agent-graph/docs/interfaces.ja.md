# Moon Agent Graph Runtime Interfaces

## ステータスと規約

このドキュメントは、ネイティブ非同期MVPのレビュー済み公開契約を定義します。

スニペットは、ネイティブ非同期MVPの実装済みかつ検証済みの公開契約を記録しています。

実装は現在のMoonBitの規約に従います：

- `moon.mod` と `moon.pkg` が設定フォーマットです。
- `preferred_target = "native"` と `supported_targets = "native"` は必須です。
- パブリックな識別子ラッパーは `Eq`、`Hash`、`Debug` を導出します。
- 同期バリデーションとルーティングは明示的な `raise` アノテーションを使用します。
- 非同期関数は暗黙的に raise します。
- ジェネリックなランタイム動作は型付き関数フィールドを使用します。
- 非ジェネリックなランタイムポリモーフィズムは `pub(open) trait` とトレイトオブジェクトを使用する場合があります。
- パブリックなコレクションは、内部コレクションのコンパイル済みミュータブルエイリアスとして返されません。

## 識別子

```moonbit
pub struct NodeId(String) derive(Eq, Hash, Debug)
pub struct RunId(String) derive(Eq, Hash, Debug)
pub struct ResourceKey(String) derive(Eq, Hash, Debug)
pub struct CodingAgentId(String) derive(Eq, Hash, Debug)
pub struct SessionId(String) derive(Eq, Hash, Debug)
```

各識別子にはバリデーション付きのコンストラクタまたはパーサーがあります。

```moonbit
pub(all) suberror IdError {
  EmptyId(kind~ : String)
} derive(Debug)

pub fn NodeId::parse(value : String) -> NodeId raise IdError
pub fn NodeId::to_string(self : NodeId) -> String
```

他の識別子型にも同等のAPIが提供されます。

マップのキー型は `Eq` と `Hash` の両方を導出します。

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
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)
```

ノード出力には、2番目のイベントキューは含まれません。

ノードは必要に応じてコンテキストを通じてライブイベントを発行し、ランタイムは自身でライフサイクルイベントを発行します。

## イベントシンク

MVPのイベントシンクは同期です。

これによりイベントの順序が決定論的に保たれ、ランタイムの各遷移間に非同期処理が入ることを防ぎます。

```moonbit
pub(all) struct EventSink {
  emit : (GraphEvent) -> Unit raise
}

pub fn EventSink::EventSink(emit : (GraphEvent) -> Unit raise) -> EventSink
pub fn EventSink::discard() -> EventSink
pub fn EventSink::try_emit(self : EventSink, event : GraphEvent) -> Unit
```

外部の非同期テレメトリアダプターはイベントをバッファリングし、個別に所有するタスクで排出することができます。

イベントシンクの失敗は、ベストエフォートの診断報告後にランタイムによってキャッチされ無視されます。

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

ランタイムは `deadline_ms` を、設定されている場合のノードタイムアウトヒント（ミリ秒単位）として提供します。このフィールドを通じてタイムアウトを強制することはありません。

MVPにはカスタムキャンセレーショントークンはありません。

非同期ノードコードは、通常の非同期呼び出しと `moonbitlang/async` のタスク状態を通じてキャンセレーションを監視します。

キャッチオールループは、`@async.is_being_cancelled()` が `true` のときに停止しなければなりません。

## Node

MoonBitのトレイトは、グラフの `S` および `P` 固有のコールバックコンテナに使用する必要はありません。

```moonbit
pub(all) struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}
```

非同期コールバックはドメインの `suberror` または低レベルのエラーを raise する場合があります。

ランタイムはそのエラーをキャッチし、ノードIDとステップでラップします。

```moonbit
pub fn[S, P] function_node(
  id : NodeId,
  metadata : NodeMetadata,
  execute : async (NodeContext, S) -> NodeOutput[P],
) -> Node[S, P]
```

## Router

MVPでは、ノードごとに1つのルーターを許可します。

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
  artifacts : ReadOnlyArray[Artifact]
} derive(Debug)
```

`declared_routes` には、`evaluate` が `Route::To` を通じて返す可能性のあるすべてのノードIDと、オプションの表示用メタデータが含まれます。

コンパイル時には、宣言されたターゲットを使用して宛先の検証と到達可能性のチェックが行われます。

実行時に、宣言されていないターゲットを返すことは、そのノードが存在する場合でも契約違反となります。

ルーターは同期的であり、I/Oの実行、モデルの呼び出し、コマンドの実行、状態の変更を行ってはなりません。

`RouterMetadata.description` と `DeclaredRouteMetadata.label` は、検査ツール向けのオプションの表示ヒントです。ルート評価には影響しません。

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

Reducerは唯一のランタイム状態更新パスです。

Reducerは同じ状態とパッチに対して決定論的でなければなりません。

グラフ固有のコードは、状態値が永続的スタイルの値であるか、制御されたミュータブルフィールドを含むかを決定します。

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

グラフの変更メソッドは、ローカルの重複を即座に拒否します。

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

コンパイルは不変のノードとルーターの値をプライベートな永続 HashMap に格納します。コンパイル後にビルダーを変更しても、コンパイル済みの構造は変更されません。

クエリメソッドはそのストレージのミュータブルエイリアスを公開しません。

`snapshot` は、検査ツールが使用する決定論的でコールバックを含まない構造を返します。

## 可視化

オプションの `totto2727/moon-agent-graph/visualization` パッケージは、ランタイムコールバックを公開せずにコンパイル済みグラフを Mermaid としてレンダリングします。

```moonbit
pub fn[S, P] to_mermaid(graph : CompiledGraph[S, P]) -> String
```

レンダラーは `core` メタデータのノード説明、ルーター説明、宣言済みルートラベルを使用します。ランタイムでのみ判定できる条件や `End`、`Fail` の結果は推論しません。

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

`max_steps` は正の値でなければなりません。

タイムアウト値は、指定する場合は正の値でなければなりません。

```moonbit
pub(all) struct RunResult[S] {
  run_id : RunId
  final_state : S
  steps : Int
} derive(Debug)
```

`RunResult` は正常完了のみを表します。

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

固定の `Unit` グループ結果により、ネイティブプロセス所有権ハンドルをグラフの状態型から独立させつつ、ランタイムはグループが終了するまで呼び出し内部に成功した `RunResult[S]` を保持します。

呼び出し元は、`invoke` を実行するタスクをキャンセルすることでキャンセレーションを制御します。

ランタイムは `RunStarted` の後、`RunCompleted`、`RunFailed`、`RunCancelled` のうち正確に1つを発行します。

キャンセルエラーは、クリーンアップとベストエフォートのイベント発行後に再 raise されます。

## ランタイムエラー

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

アダプターは独自の `suberror` 型を定義し、ランタイムがそれらを原因として保持できるようにします。

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

コールバック境界により、並列のMoonLLMクライアント階層を考案することなく、決定論的なフェイクが可能になります。

構造化出力ノードは、MoonLLMのResponses APIが適切なインターフェースである場合に、異なるリクエスト/レスポンスペアを使用する場合があります。

## コーディングエージェントのリクエストとレスポンス

```moonbit
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
  artifacts : ReadOnlyArray[Artifact]
  raw_output : Json?
} derive(Debug)
```

キャンセルは、成功した `Cancelled` レスポンスではなく、raise されたタスクキャンセルエラーによって表現されます。

アダプターは、そのSDKが信頼できる変更セットを公開しない場合、空の `changed_files` 配列を返すことがあります。

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
  environment : @immut_hashmap.HashMap[String, String]
  events : EventSink
} derive(Debug)
```

現在のCodexおよびOpenCodeアダプターがクライアントとスレッドを作成する際にサポートされている値を適用するため、環境とポリシーはセッションオープン時の設定です。

アダプター固有のオプションはアダプターのコンストラクタに残ります。

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

ランタイムは、あるアダプターによって作成されたセッションを別のアダプターに渡すことは決してありません。

`close` はセッション境界で冪等であり、リソースストアはそれを最大でも1回だけ呼び出します。

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
  CloseFailed(errors~ : ReadOnlyArray[Error])
} derive(Debug)
```

MVPストアは意図的に一般的なコーディングエージェントセッションインターフェースに特化しています。

異種の任意リソースコンテナは、MoonBitが取得のための具体的な型付きユースケースを持つまで先送りされます。

実行スコープのセッションは、1回の呼び出し内でリソースキーによって再利用されます。

ノードスコープのセッションは `owner` が必要であり、そのノード試行後にクローズされます。実行スコープのセッションはオーナーを省略し、キーによって再利用されます。

オープンに失敗したものはストアに挿入されることはありません。

リソースは取得の逆順でクローズされます。

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

## Codexアダプター

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

アダプターは、コンテキスト環境、ワークスペースルート、追加の書き込み可能ルート、承認、ネットワーク、および指定されたオプションを、固定されたCodex SDKにマッピングします。スレッドの最終レスポンスを `summary` として、SDKスレッドIDを `continuation_id` として、検出された完了パッチパスを `changed_files` として返し、アーティファクトはなく、生の出力もありません。セッションをクローズすると、以降の実行は `CodexAdapterError::SessionClosed` を raise します。

## OpenCodeアダプター

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

アダプターは `totto2727/opencode-sdk` をCLI SDKとして使用し、別途管理されている `opencode-server-sdk` をインポートしません。SDKスレッドを開始または再開し、各指示を `opencode run --format json` を通じて実行し、相対コンテキストファイルをワークスペースルートに対して解決し、それらを繰り返しのCLIファイル入力として転送します。継承されたプロセス環境は保持され、アダプターのエントリが次に適用され、呼び出し元のコンテキストエントリが優先されます。正常なターンは、最終テキストを `summary` として、SDKスレッドIDを `continuation_id` として返し、`changed_files`、アーティファクト、生の出力は空になります。これは、現在のOpenCodeイベントモデルがこの境界で信頼性のあるファイル変更セットや汎用の生JSON値を公開しないためです。各ターンは独自のサブプロセスを所有し、キャンセルおよび具体的な `OpenCodeSdkError` 値はCLI SDKから伝播されます。論理セッションのクローズは冪等であり、以降の実行は `OpenCodeAdapterError::SessionClosed` を raise します。

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

## 確定したMVPの設計判断

1. 実行はネイティブ専用かつ非同期です。
2. グラフの実行は逐次的です。
3. サイクルは許可され、`max_steps` によって制限されます。
4. 各ノードには正確に1つのルーターがあります。
5. ルーターの宛先は宣言され、コンパイル時に検証されます。
6. 状態は呼び出しローカルであり、reducerを通じてのみ更新されます。
7. キャンセルはタスクキャンセルを使用します。
8. 非同期クリーンアップは明示的であり、キャンセルから保護され、タイムアウトで制限されます。
9. リソーススコープは各コーディングエージェントノードの仕様によって選択されます。
10. CodexとOpenCodeは、1つのセッション契約の背後にある別個のアダプターです。
11. 並列ノード、チェックポイント、永続状態、アプリケーションスコープのリソースは先送りされます。

## 参考文献

- [MoonBit async programming](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBit error handling](https://docs.moonbitlang.com/en/latest/language/error-handling.html)
- [MoonBit methods and traits](https://docs.moonbitlang.com/en/latest/language/methods.html)
- [MoonBit deriving traits](https://docs.moonbitlang.com/en/latest/language/derive.html)
- [MoonBit module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
