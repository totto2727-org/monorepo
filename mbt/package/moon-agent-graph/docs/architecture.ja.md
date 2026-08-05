# Moon Agent Graph ランタイムアーキテクチャ

## ステータス

このドキュメントは、レビュー済みのアーキテクチャベースラインと、Moon Agent Graph ランタイム MVP の現在の実装状況を記録したものです。

実装ベースラインは、MoonBit コンパイラ `v0.10.4`、Moon `0.1.20260713`、`moonbitlang/async@0.20.1`、`moonbitlang/x@0.4.38`、`DC-Z-lab/moonllm@0.1.0`、`totto2727/agent-cli-sdk@0.1.0`、`totto2727/codex-sdk@0.0.0`、および `totto2727/opencode-sdk@0.1.1` です。

ランタイムはネイティブのみで、非同期です。

## 実装状況

ネイティブ実装には、コアとなるグラフコンパイラと逐次ランタイム、実行およびノードリソースのライフサイクル管理、ファンクションノード、MoonLLM コールバックノード、コーディングエージェントノード、Codex および OpenCode アダプター、決定論的テストヘルパー、決定論的エンドツーエンドワークフローテストが含まれます。

先送りされた作業には、並列ノードスケジューリング、永続的チェックポイントまたは耐久性のある実行、人間による承認の一時停止、サブグラフ、分散ワーカー、プロバイダー完全な権限マッピング、および実際のクレデンシャルを持つプロバイダーによるエンドツーエンドテストが含まれます。

## 目的

ランタイムは、その遷移が検証された有向グラフを形成する型付きステートマシンを実行します。

MVP は次の3つの実行セマンティクスをサポートします。

- ファンクションノードは、任意の MoonBit コールバックを実行します。
- LLM ノードは、MoonLLM を通じてリモートモデルを呼び出します。
- コーディングエージェントノードは、Codex または OpenCode のいずれかにワークスペース作業を委任します。

ノードカテゴリは、トランスポートではなく実行セマンティクスに基づいています。

## レビュー済みの決定事項

元の設計方針は、以下の修正を加えて維持されます。

1. モジュールは `preferred_target = "native"` と `supported_targets = "native"` の両方を宣言します。
2. すべての非同期処理は `moonbitlang/async` の構造化並行処理を使用します。
3. 各グラフ呼び出しは1つのタスクグループを所有し、その呼び出しのために生成されたすべてのサブプロセスまたはバックグラウンドタスクはそのグループに属します。
4. キャンセルは `moonbitlang/async` のタスクキャンセルを使用します。MVP は2つ目のキャンセルトークンの抽象化を導入しません。
5. 非同期 API は MoonBit のエラーを発生させます。すべての結果を `Result` でラップすることはありません。
6. ドメイン障害は `suberror` 値を使用し、予期しない低レベルのエラーは `Error` の原因として保持されます。
7. ジェネリックなグラフコールバックは型付き関数フィールドを使用します。なぜなら、その状態とパッチの型はグラフ固有だからです。
8. MVP では、ノードは最大1つのルーターを持ちます。これにより、複数の outgoing エッジ間の順序の曖昧さが排除されます。
9. ルーターは可能なすべての宛先ノード ID を宣言するため、コンパイル時に到達可能性と宛先を検証できます。
10. インメモリの実行状態は呼び出しによって直接所有されます。耐久性のある、またはプラグイン可能な状態ストアは、チェックポイントが設計されるまで先送りされます。
11. OpenCode は、リポジトリの CLI SDK を利用したコーディングエージェントアダプターであり、`opencode run --format json` を実行します。別の `opencode-server-sdk` はグラフアダプターの一部ではありません。
12. すべての Codex または OpenCode のターンは、構造化並行処理を通じて独自の CLI サブプロセスを所有し、呼び出し元のキャンセルはその子プロセスを停止して待機してから戻る必要があります。

## コンポーネントモデル

```mermaid
flowchart TD
  Definition["GraphDefinition[S, P]"] --> Compiler["Graph compiler"]
  Compiler --> Compiled["CompiledGraph[S, P]"]
  Compiled --> Runtime["GraphRuntime[S, P]"]
  Runtime --> State["Invocation-local S"]
  Runtime --> Reducer["Reducer[S, P]"]
  Runtime --> Events["EventSink"]
  Runtime --> Resources["Run resource store"]
  Runtime --> Function["Function node"]
  Runtime --> LLM["MoonLLM node"]
  Runtime --> AgentNode["Coding-agent node"]
  AgentNode --> Codex["Codex session adapter"]
  AgentNode --> OpenCode["OpenCode session adapter"]
  OpenCode --> OpenCodeSDK["OpenCode CLI SDK"]
  OpenCodeSDK --> AgentCLI["Shared agent CLI process runtime"]
```

コアランタイムは、Codex、OpenCode、または MoonLLM の具象型をインポートしません。

統合パッケージは、それらの具象 SDK をコアのコールバックおよびセッション契約に適応させます。

ランタイムは各呼び出しに `TaskGroup[Unit]` を使用するため、プロセスの所有権はグラフの状態型に依存しません。

## ネイティブ非同期実行モデル

`GraphRuntime::invoke` は非同期操作です。

呼び出しはネストされたタスクグループを開き、そのボディ内で完全な実行を行います。

タスクグループは以下を所有します。

- ランタイムによって生成されたノード処理。
- ターン中に開始された Codex サブプロセス。
- ターン中に開始された OpenCode サブプロセス。
- タイムアウトヘルパータスク。
- 任意のアダプターバックグラウンドリーダー。

MVP はノードを逐次的に実行しますが、プロセスの所有権、キャンセル、タイムアウト、および将来の限定された並列実行のために、構造化並行処理は依然として必要です。

呼び出し元は、呼び出し元が所有するタスクグループ内で呼び出しを spawn し、返された `Task` をキャンセルすることで、呼び出しをキャンセルできます。

```moonbit
@async.with_task_group() <| group => {
  let task = group.spawn(async fn() { runtime.invoke(initial_state, options) })
  // 呼び出し元は後で task.cancel() を呼び出せます。
  task.wait()
}
```

ランタイムは、キャンセルエラーを飲み込んで通常の成功結果に変換してはいけません。

キャッチオールループは、再試行または継続する前に `@async.is_being_cancelled()` をチェックします。

## 実行ライフサイクル

```mermaid
sequenceDiagram
  participant Caller
  participant Runtime
  participant Group as Run TaskGroup
  participant Node
  participant Reducer
  participant Router
  participant Resources

  Caller->>Runtime: invoke(initial_state, options)
  Runtime->>Group: with_task_group
  Runtime->>Runtime: emit RunStarted

  loop Until End, error, cancellation, or step limit
    Runtime->>Node: execute(context, current_state)
    Node-->>Runtime: NodeOutput
    opt Patch exists
      Runtime->>Reducer: apply(current_state, patch)
      Reducer-->>Runtime: next_state
    end
    Runtime->>Router: evaluate(next_state, completion)
    Router-->>Runtime: Route
  end

  Runtime->>Resources: close node and run resources
  Runtime->>Runtime: emit one terminal event
  Group-->>Runtime: all owned tasks terminated
  Runtime-->>Caller: RunResult or raised error
```

ルーターはパッチ適用後の状態を観測します。

ステップカウンターは、ノード実行の試行ごとに正確に1回インクリメントされます。

`max_steps = 0` は、エントリーノードを実行する前に実行を拒否します。

## クリーンアップとエラーの保持

リソースのクリーンアップは、成功、失敗、タイムアウト、およびキャンセル時に実行されます。

実行本体は、`@async.with_task_group` から戻る前に、実行スコープのリソースを明示的にクローズします。

非同期 I/O を実行するクリーンアップは、呼び出し元のキャンセルから保護され、ハードタイムアウトによって制限されます。

```moonbit
@async.protect_from_cancel(
  async fn() {
    @async.with_timeout(
      cleanup_timeout_ms,
      async fn() { resources.close_all() },
    )
  },
)
```

保護は可能な限り狭い範囲に保ちます。広範なキャンセル保護は、タイムアウトとキャンセルの抽象化を壊す可能性があるためです。

リソースは取得の逆順でクローズされます。

主要な処理とクリーンアップの両方が失敗した場合、主要なエラーが優先され、クリーンアップエラーはランタイム障害レコードに付加されます。

クリーンアップのみが失敗した場合、実行はクリーンアップエラーで失敗します。

ランタイムは、1つのクローズ操作が失敗した後も、残りのリソースのクローズを続行します。

## グラフセマンティクス

グラフ定義は、組み立て中はミュータブルです。

コンパイルは、推移的に不変なグラフ構造の値をプライベートな永続 HashMap に格納します。その後に定義を変更してもビルダーのエントリが置き換わるだけで、コンパイル済みグラフから到達可能な値は変更できません。

コンパイルは以下を検証します。

- 空でないエントリーノードが設定されていること。
- ノード ID が一意であること。
- エントリーノードが存在すること。
- すべてのノードが正確に1つのルーターを持つこと。
- 宣言されたすべてのルーター宛先が存在すること。
- すべてのノードがエントリーノードから宣言された宛先を通じて到達可能であること。
- ID が有効であること。

サイクルは許可されます。

コンパイルされたグラフは、ミュータブルな内部マップや配列を公開しません。

MVP は、ルーターの宣言された宛先リストから省略された動的な宛先をサポートしません。

## ステートセマンティクス

状態型とパッチ型は、グラフ作成者によって提供されます。

ノードは状態値を読み取り、パッチを返す場合があります。

リデューサーは、状態を変更する唯一のランタイムパスです。

リデューサーは同期的かつ決定論的です。

呼び出しは現在の状態をローカルに保持します。これは、MVP が逐次的で非耐久性だからです。

チェックポイント、サスペンド/レジューム、および永続的ストアは、別個の一貫性とシリアライゼーションの設計を必要とし、MVP の一部ではありません。

## ノードセマンティクス

### ファンクションノード

ファンクションノードは、非同期の MoonBit コールバックをラップします。

I/O を実行することもありますが、ルーティングのみのロジックはルーターに属します。

`NodeContext.deadline_ms` は、ノードタイムアウトが設定されていない場合は `None` であり、設定されている場合はノードタイムアウト期間をミリ秒単位の `Int64` として保持します。これは現在のノード試行のメタデータであり、絶対的な壁時計のデッドラインではありません。ランタイムは、`@async.with_timeout` を使用して同じ設定された期間を強制します。

### LLM ノード

LLM ノードは以下を実行します。

- 状態から型付きの MoonLLM リクエストを構築します。
- 提供された非同期 MoonLLM 境界を呼び出します。
- レスポンスをノード出力にデコードします。

コールバックは完全な MoonLLM レスポンスを受け取るため、グラフ作成者が必要とする場合、そのデコーダーはアーティファクトやイベントで使用情報を保持できます。現在のジェネリックノードは自動的に使用量を出力しません。

統合パッケージは、具象の `@moonllm.Client` を所有します。

コアパッケージは非同期コールバックを受け取るため、テストは決定論的な偽装を提供できます。

### コーディングエージェントノード

コーディングエージェントノードは以下を実行します。

- 共通のコーディングエージェントリクエストを構築します。
- プロセスを通常の型付きリソースとして保存し、リソーススコープに従って取得または再利用します。
- リクエストを実行します。
- レスポンスをパッチとアーティファクトに変換します。

Codex と OpenCode はセッションセマンティクスを共有しますが、SDK 固有のオプションはアダプター内に保持します。

## Codex アダプター

Codex アダプターは、共通リクエストをリポジトリの `totto2727/codex-sdk` にマッピングします。

Codex セッションは1つの `Thread` を所有します。

`Thread::run` および `Thread::run_streamed` は、ターンごとにネイティブサブプロセスを開始およびクリーンアップします。

タスクキャンセルは、上流のアボートシグナルに相当するネイティブのものです。

Codex スレッドの継続は `Thread::id` を使用します。

現在の SDK イベントモデルが実際にそのデータを公開しない限り、アダプターは stdout、stderr、または変更されたファイルデータを約束してはいけません。

## OpenCode アダプター

OpenCode アダプターは以下を所有します。

- 1つのリポジトリ `@opencode_sdk.Thread`。
- 各ターンに適用されるワーキングディレクトリとスレッドオプション。
- JSONL イベントから学習された、または再開用に提供された論理的な OpenCode セッション ID。
- セッションミューテックスと論理的なクローズ状態。

リポジトリの `totto2727/opencode-sdk` は OpenCode CLI SDK です。これは `opencode run --format json` を呼び出します。一方、`totto2727/opencode-server-sdk` はオプションの `opencode serve` ライフサイクルを別途所有し、Moon Agent Graph によってインポートされることはありません。

アダプターは、オープン時に CLI スレッドを作成または再開します。各 `execute` は `Thread::run` を呼び出し、これは1つのネイティブサブプロセスを開始し、型付き JSONL イベントを解析し、最終テキストをキャプチャし、次のターン用に出力されたセッション ID を保持します。

相対コンテキストファイルはワークスペースルートに対して解決され、型付きローカルファイル入力として渡されるため、SDK は繰り返し `--file` フラグを出力します。指示はファイルパスをテキストに埋め込む代わりに、CLI プロンプトのまま残ります。

アダプターは継承されたプロセス環境をスナップショットし、設定されたアダプター変数を適用し、次にオープンコンテキスト環境を適用して、呼び出し元の値を優先します。実行可能パス、型付き設定、再開 ID、モデル、エージェント、ワーキングディレクトリ、バリアント、タイトル、および思考オプションを CLI SDK にマッピングします。

アイドルスレッドに属する永続的なサブプロセスがないため、セッションクローズは論理的です。実行中の処理は `agent-cli-sdk` 内でその子プロセスを所有します。キャンセルはその子プロセスをハードストップして待機します。一方、CLI の終了、JSONL、およびターンの失敗は、具象の `OpenCodeSdkError` を保持します。クローズされたセッションは `OpenCodeAdapterError::SessionClosed` を発生させます。

## パッケージレイアウト

実装は、少数の非循環パッケージを持つ1つの MoonBit モジュールです。

```text
mbt/package/moon-agent-graph/
├── moon.mod
├── README.mbt.md
├── README.md -> README.mbt.md
├── docs/
└── src/
    ├── core/
    ├── moonllm/
    ├── coding_agent/
    ├── integrations/
    │   ├── codex/
    │   └── opencode/
    ├── testing/
    ├── visualization/
    ├── e2e/
    ├── test/
    └── examples/
        ├── basic/
        └── visualization/
```

`core` には、ID、グラフコンパイル、ノードおよびルーターコールバックコンテナ、リデューサーセマンティクス、実行イベント、実行リソース、および逐次ランタイムが含まれます。

`moonllm` は core と MoonLLM をインポートします。

`coding_agent` は core をインポートし、共通のエージェントセッション契約とノードファクトリーを定義します。

2つのアダプターパッケージは `coding_agent` とそれぞれの具象 SDK をインポートします。

`testing` には、再利用可能な偽装とレコーダーが含まれます。

`visualization` は `core` をインポートし、コールバックを含まないコンパイル済みグラフのスナップショットを、決定論的な Mermaid フローチャートとしてレンダリングします。

`e2e` には、再利用可能な決定論的エンドツーエンドワークフローのサポートが含まれます。

`test` には、公開された `core`、`moonllm`、`coding_agent`、アダプター、`testing`、`e2e` の各パッケージ面を接続するネイティブのブラックボックス統合テストが含まれます。

`examples/basic` は、公開されている `core` パッケージのみをインポートする実行可能なネイティブの例です。

`examples/visualization` は、公開されている `core` と `visualization` パッケージを使用して、ルーターの説明とラベル付き条件分岐を示します。

モジュール、共有エージェント CLI SDK、Codex SDK、OpenCode SDK、および MoonLLM は `moonbitlang/async@0.20.1` を解決します。Codex SDK とグラフモジュールは `moonbitlang/x@0.4.38` を解決します。実装されたアダプターに対して、非同期ランタイムのバージョン調整作業は残っていません。

## MVP スコープ

MVP に含まれるもの:

- ネイティブ非同期実行。
- ファンクション、LLM、およびコーディングエージェントノード。
- 型付き状態とパッチ。
- 条件付きルーティング。
- ステップ制限付きのサイクル。
- ノードタイムアウト。
- タスクキャンセル。
- CodingAgentプロセスを含む、実行スコープおよびノードスコープの異種リソース。
- インメモリのイベントと状態。
- Codex および OpenCode アダプター。
- 決定論的テストヘルパーとエンドツーエンドワークフローカバレッジ。

MVP から除外されるもの:

- 並列ノード実行。
- 永続的チェックポイント。
- 耐久性のある実行。
- 人間による承認の一時停止。
- サブグラフ。
- 分散ワーカー。
- プロバイダー完全な権限マッピング。
- 実際のクレデンシャルを持つプロバイダーによるエンドツーエンドテスト。

## 参考文献

- [MoonBit 非同期プログラミングと構造化並行処理](https://docs.moonbitlang.com/en/latest/language/async-experimental.html)
- [MoonBit エラーハンドリング](https://docs.moonbitlang.com/en/latest/language/error-handling.html)
- [MoonBit メソッド、トレイト、およびトレイトオブジェクト](https://docs.moonbitlang.com/en/latest/language/methods.html)
- [MoonBit モジュール設定とネイティブターゲット宣言](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBit パッケージ設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- [moonbitlang/async パッケージドキュメント](https://mooncakes.io/docs/moonbitlang/async)
- [MoonLLM リポジトリ](https://github.com/DC-Z-lab/moonllm)
- [リポジトリの移植元である Codex TypeScript SDK リファレンス](https://github.com/openai/codex/tree/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript)
- [OpenCode CLI ドキュメント](https://opencode.ai/docs/cli/)
- [リポジトリ CLI SDK の移植元である OpenCode `run` JSONL 実装](https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts)
