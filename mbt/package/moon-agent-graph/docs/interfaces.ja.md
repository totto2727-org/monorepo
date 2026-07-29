# Moon エージェントグラフランタイムインターフェース

## ステータスと規約

このドキュメントは、ネイティブ非同期MVPのレビュー済み公開契約を定義します。

スニペットは、実装ワークストリームW0におけるコンパイルスパイクによってロックされるAPIシェイプです。

実装は現在のMoonBit規約に従います：

- `moon.mod` と `moon.pkg` は設定形式です。
- `preferred_target = "native"` と `supported_targets = "native"` は必須です。
- 公開識別子ラッパーは `Eq`、`Hash`、`Debug` を導出します。
- 同期バリデーションとルーティングは明示的な `raise` アノテーションを使用します。
- 非同期関数は暗黙的に raise します。
- ジェネリックなランタイム動作は型付き関数フィールドを使用します。
- 非ジェネリックなランタイムポリモーフィズムは `pub(open) trait` とトレイトオブジェクトを使用する場合があります。
- 公開コレクションは、コンパイル済み内部コレクションのミュータブルエイリアスとして返されません。

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

他の識別子タイプにも同等のAPIが提供されます。

マップキータイプは `Eq` と `Hash` の両方を導出します。

## Route

```moonbit
pub(all) enum Route {
  To(NodeId)
  End
  Fail(String)
} derive(Debug)
```

`Fail` は意図的なグラフドメイン障害を表します。

予期しないルーター障害は raise され、ランタイムによってラップされます。

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

ノード出力には2番目のイベントキューは含まれません。

ノードは必要なときにコンテキストを介してライブイベントを発行し、ランタイムは自身でライフサイクルイベントを発行します。

## イベントシンク

MVPイベントシンクは同期です。

これによりイベントの順序が決定論的に保たれ、ランタイム遷移のたびに非同期処理が導入されるのを防ぎます。

```moonbit
pub(all) struct EventSink {
  emit : (GraphEvent) -> Unit
}
```

外部の非同期テレメトリアダプターはイベントをバッファリングし、別に所有するタスクで排出する場合があります。

イベントシンクの障害はランタイムによってキャッチされ、ベストエフォートの診断報告後に無視されます。

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
```

MVPにはカスタムキャンセレーショントークンはありません。

非同期ノードコードは、通常の非同期呼び出しと `moonbitlang/async` タスク状態を通じてキャンセレーションを監視します。

キャッチアーループは `@async.is_being_cancelled()` が true の場合に停止する必要があります。

## Node

MoonBitのトレイトは、グラフの `S` および `P` 固有のコールバックコンテナに使用する必要はありません。

```moonbit
pub(all) struct Node[S, P] {
  id : NodeId
  metadata : NodeMetadata
  execute : async (NodeContext, S) -> NodeOutput[P]
}
```

非同期コールバックはドメイン `suberror` またはより低レベルのエラーを raise する場合があります。

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

`declared_targets` には、`evaluate` が `Route::To` を通じて返す可能性のあるすべてのノードIDが含まれます。

コンパイルは、宣言されたターゲットを宛先の検証と到達可能性のために使用します。

実行時に、宣言されていないターゲットを返すことは、そのノードが存在する場合でも契約違反です。

ルーターは同期であり、I/Oの実行、モデルの呼び出し、コマンドの実行、状態の変更を行ってはなりません。

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

グラフ固有のコードは、状態値が永続的なスタイルの値であるか、制御されたミュータブルフィールドを含むかを決定します。

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

グラフ変更メソッドはローカルの重複を即座に拒否します。

相互参照および到達可能性の失敗は `compile` によって報告されます。

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

コンパイルは、定義マップとノードごとの配列を分離したプライベートストレージにコピーします。

クエリメソッドはそのストレージのミュータブルエイリアスを公開しません。

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

失敗とキャンセレーションは raise されます。

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

pub async fn[S, P] GraphRuntime::invoke(
  self : GraphRuntime[S, P],
  initial_state : S,
  options? : RunOptions = RunOptions(),
) -> RunResult[S]
```

`invoke` は実行ごとのリソースストアとネストされた `TaskGroup[Unit]` を作成します。

固定の `Unit` グループ結果により、ネイティブプロセス所有権ハンドルがグラフ状態型から独立した状態を保ち、ランタイムは成功した `RunResult[S]` をグループが終了するまで呼び出し内部に保存します。

呼び出し元は、`invoke` を実行するタスクをキャンセルすることでキャンセレーションを制御します。

ランタイムは `RunStarted` の後に `RunCompleted`、`RunFailed`、`RunCancelled` のうち正確に1つを発行します。

キャンセレーションエラーは、クリーンアップとベストエフォートのイベント発行後に再 raise されます。

## ランタイムエラー

```moonbit
pub(all) struct RunFailure {
  primary : Error
  cleanup : Array[Error]
} derive(Debug)

pub(all) suberror GraphRuntimeError {
  NodeFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  ReduceFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteFailed(node_id~ : NodeId, step~ : Int, cause~ : Error)
  RouteContractViolated(from~ : NodeId, to~ : NodeId)
  StepLimitExceeded(limit~ : Int)
  ExplicitFailure(node_id~ : NodeId, message~ : String)
  ResourceCleanupFailed(failure~ : RunFailure)
} derive(Debug)
```

アダプターは独自の `suberror` 型を定義し、ランタイムがそれらを原因として保持できるようにします。

Display実装は、認証情報、環境シークレット、生の認証ヘッダーを秘匿化します。

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

コールバック境界により、並列のMoonLLMクライアント階層を発明することなく、決定論的なフェイクが可能になります。

MoonLLMのResponses APIが適切なインターフェースである場合、構造化出力ノードは異なるリクエスト/レスポンスペアを使用する場合があります。

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

キャンセレーションは、成功した `Cancelled` レスポンスではなく、raise されたタスクキャンセレーションエラーによって表現されます。

アダプターは、そのSDKが信頼できる変更セットを公開しない場合、空の `changed_files` 配列を返す場合があります。

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

環境とポリシーはセッションオープン時の設定です。これは、現在のCodexおよびOpenCodeアダプターがクライアント、スレッド、またはサーバーの作成時にそれらのいくつかを適用するためです。

アダプター固有のオプションはアダプターコンストラクターに残ります。

## コーディングエージェントセッション

共通のセッションインターフェースは非ジェネリックであり、非同期トレイトオブジェクトを使用します。

```moonbit
pub(open) trait CodingAgentSession {
  id(Self) -> SessionId?
  async fn execute(Self, CodingAgentRequest) -> CodingAgentResponse
  async fn close(Self) -> Unit
}

pub(all) struct CodingAgent {
  id : CodingAgentId
  open : async (CodingAgentOpenContext) -> &CodingAgentSession
}
```

ランタイムは、あるアダプターによって作成されたセッションを別のアダプターに渡すことは決してありません。

`close` はセッション境界において冪等であり、リソースストアはそれを最大1回呼び出します。

実行中のセッションは、非同期呼び出しが終了する前に、所有するプロセスの作業を終了またはキャンセルすることでタスクキャンセレーションに応答します。

## リソーススコープとストア

```moonbit
pub(all) enum ResourceScope {
  Node
  Run
} derive(Debug, Eq)

pub struct RuntimeResourceStore

pub async fn RuntimeResourceStore::acquire_agent_session(
  self : RuntimeResourceStore,
  key : ResourceKey,
  scope : ResourceScope,
  open : async () -> &CodingAgentSession,
) -> &CodingAgentSession

pub async fn RuntimeResourceStore::release_node(
  self : RuntimeResourceStore,
  node_id : NodeId,
) -> Unit

pub async fn RuntimeResourceStore::close_all(
  self : RuntimeResourceStore,
) -> Unit
```

MVPストアは、一般的なコーディングエージェントセッションインターフェースに意図的に特化しています。

異種の任意リソースコンテナは、MoonBitが取得のための具体的な型付きユースケースを持つまで延期されます。

実行スコープのセッションは、1回の呼び出し内でリソースキーによって再利用されます。

ノードスコープのセッションは、そのノードの試行後にクローズします。

オープンの失敗はストアに挿入されることはありません。

リソースは取得順序の逆順でクローズします。

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

## Codexアダプター契約

Codexアダプターは：

- 環境と実行可能ファイルオプションを指定して `@codex_sdk.Codex` を作成します。
- `Thread` を開始または再開します。
- ワークスペース、追加ディレクトリ、サンドボックス、承認、ネットワーク、ウェブ検索、モデルオプションを `ThreadOptions` にマッピングします。
- `Thread::run` または `Thread::run_streamed` を呼び出します。
- `Thread::id` を継続IDとして使用します。
- ネイティブCLIプロセスをキャンセルするためにタスクキャンセレーションに依存します。
- 現在のSDKにはクローズする永続的なクライアントプロセスがないため、進行中の処理が終了した後、セッションクローズを冪等なno-opとして実装します。

## OpenCodeアダプター契約

OpenCodeアダプターは：

- `CodingAgentOpenContext` を通じて呼び出しの `TaskGroup[Unit]` を受け取ります。
- `@opencode.create_opencode_server(group, options)` を起動します。
- `server.moonllm_config()` からクライアントを構築します。
- `POST /session` でOpenCodeセッションを作成します。
- セッションメッセージエンドポイントを通じて指示を送信します。
- OpenCodeセッションIDを継続IDとして保持します。
- すべての終了パスでサーバーを明示的にクローズします。
- 共通のコーディングエージェントAPIを通じてサーバーURLを公開しません。

## 確定したMVP決定事項

1. 実行はネイティブのみかつ非同期です。
2. グラフ実行は逐次です。
3. サイクルは許可され、`max_steps` によって制限されます。
4. 各ノードには正確に1つのルーターがあります。
5. ルーターの宛先は宣言され、コンパイル時に検証されます。
6. 状態は呼び出しローカルであり、リデューサーを通じてのみ更新されます。
7. キャンセレーションはタスクキャンセレーションを使用します。
8. 非同期クリーンアップは明示的であり、キャンセレーションから保護され、タイムアウトで制限されます。
9. OpenCodeはデフォルトで実行スコープの再利用になります。
10. CodexとOpenCodeは1つのセッション契約の背後にある別々のアダプターです。
11. 並列ノード、チェックポインティング、永続的な状態、アプリケーションスコープのリソースは延期されます。

## 参照

- [MoonBit非同期プログラミング](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBitエラーハンドリング](https://docs.moonbitlang.com/en/latest/language/error-handling.html)
- [MoonBitメソッドとトレイト](https://docs.moonbitlang.com/en/latest/language/methods.html)
- [MoonBitトレイト導出](https://docs.moonbitlang.com/en/latest/language/derive.html)
- [MoonBitモジュール設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBitパッケージ設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
