# MoonBit `pub(all)` 監査

## エグゼクティブサマリー

監査対象には、8つのMoonBitモジュールにわたって126件の `pub(all)` 型宣言があります。内訳はstructが78件、enumが32件、suberrorが16件です。このうち、呼び出し側がenumのバリアントを直接構築する必要があることが明確な宣言は18件だけです。別の37件は外部からの構築が必要ですが、既存または新規のコンストラクタや限定ファクトリを通じて公開すべきです。残りの71件は出力、エラー、ランタイム所有のコンテキスト、またはテスト用の観測値であり、通常は読み取り専用の `pub` 型にすべきです。

`totto2727/geo-mbt` はこの監査から一時的に除外しています。同モジュールにある19件の `pub(all)` 宣言は、以下の件数と推奨事項のいずれにも含めていません。

したがって、推奨するデフォルトは `pub(all)` ではなく `pub` です。`pub(all)` を使用するのは、表現可能なすべての値を直接構築できることが意図された公開契約であり、維持すべき不変条件、正規化、所有権、ライフサイクル、互換性の境界が存在しない場合に限定します。

| 推奨事項                                                   | 件数 | 意味                                                                                       |
| ---------------------------------------------------------- | ---: | ------------------------------------------------------------------------------------------ |
| `pub(all)` を維持                                          |   18 | enumバリアントの直接構築が意図された入力契約である。                                       |
| `pub` に変更し、既存のコンストラクタまたはファクトリを維持 |   21 | 外部からの構築は妥当だが、呼び出し側は既存の正規経路を使用すべきである。                   |
| `pub` に変更し、コンストラクタまたはファクトリを追加       |   16 | 外部からの構築は妥当だが、可視性を縮小する前にパッケージ側で正規経路を用意する必要がある。 |
| 読み取り専用の `pub` に変更し、外部構築を公開しない        |   71 | 出力、エラー、ランタイム所有の値、またはテスト用の観測値である。                           |

この推奨事項は2026-08-04に適用済みです。`geo-mbt` を除く `pub(all)` は意図的な入力enum 18件だけになり、その他の構築箇所はコンストラクタ、限定ファクトリ、またはパッケージ内部へ移行しました。

## 公式言語仕様上の根拠

MoonBitでは、`pub` 型は定義元パッケージの外部では読み取り専用です。外部パッケージはフィールドの参照とパターンマッチができますが、値の構築やフィールドの更新はできません。`pub(all)` はこれに加えて、表現上可能な場合に外部からの構築と変更を許可します。同一パッケージ内の実装は `pub` の制約を受けないため、パッケージは読み取り専用の公開型を返すコンストラクタやデコーダーを引き続き実装できます。[Managing Projects with Packages: Access Control](https://docs.moonbitlang.com/en/latest/language/packages.html#access-control) を参照してください。

MoonBitでは、パッケージの全メンバーへアクセスできるホワイトボックステストと、公開APIだけを参照できるブラックボックステストが区別されています。無効な内部値を必要とするテストが実装動作を検証するものである場合は、ホワイトボックステストを使用すべきです。ブラックボックステストの準備を簡単にするためだけに、プロダクションAPIを拡大すべきではありません。[Writing Tests: BlackBox Tests and WhiteBox Tests](https://docs.moonbitlang.com/en/latest/language/tests.html#blackbox-tests-and-whitebox-tests) を参照してください。

enumのコンストラクタごとに個別の可視性を指定することはできません。enumを外部から観測可能にしつつ自由な構築を禁止する必要がある場合は、読み取り専用の `pub enum` とし、必要な値だけを返すパッケージ関数を公開します。[MoonBit diagnostic E3006](https://docs.moonbitlang.com/en/latest/language/error_codes/E3006.html) を参照してください。

すでに公開済みのAPIについては、MoonBitの `#visibility(change_to="readonly", ...)` を使用すると、後で可視性を縮小する前に呼び出し側へ警告できます。[Attributes: Visibility Attribute](https://docs.moonbitlang.com/en/latest/language/attributes.html#visibility-attribute) を参照してください。

この監査で使用したローカルコンパイラは `moonc v0.10.4+2cc641edf (2026-07-15)` であり、現在v0.10.4として表示されるドキュメントの生成バージョンと一致しています。

## 判断基準

次の条件をすべて満たす場合に限り、`pub(all)` を維持します。

1. テストだけでなく、通常の外部呼び出し側が値を構築する必要がある。
2. 外部から表現可能なすべての値が有効であり、構築によって検証や正規化を回避できない。
3. パッケージ所有のライフサイクル状態、コールバック、可変ストレージ、パーサー由来の情報、リソース所有権を値が保持していない。
4. 表現へ直接アクセスできることを、将来も維持する互換性上の契約として意図している。
5. コンストラクタやファクトリを導入しても有用な境界を維持できず、単に手順が増えるだけである。

呼び出し側が返された値を参照またはパターンマッチするだけであれば、`pub` で十分です。呼び出し側がstructを作成する必要がある場合は、`pub` とコンストラクタまたはファクトリの組み合わせを優先します。呼び出し側が少数の入力モードから選択する必要があり、すべてのバリアントが有効であれば、`pub(all) enum` が適切です。

## 最もリスクの高い指摘

### P0: `RunOptions` は自身の検証を回避できる

`RunOptions::RunOptions` は0以下の `max_steps`、`node_timeout_ms`、`cleanup_timeout_ms` を拒否しますが、`pub(all) struct RunOptions` により、外部パッケージはstructリテラルを使って同じ無効な状態を構築できます。これはパッケージの検証境界を直接無効化します。型を `pub struct RunOptions` に変更し、既存の検証付きコンストラクタを維持してください。

ソース: [`runtime_types.mbt`](../../mbt/package/moon-agent-graph/src/core/runtime_types.mbt)

### P0: ランタイム所有のグラフコンテキストをstructリテラルで偽造できる

`NodeContext` と `CodingAgentOpenContext` は、実行ID、タスクグループ、イベントシンク、リソースストア、ワークスペース権限、環境状態を保持しています。これらの値はランタイムの所有関係を表すため、外部からstructリテラルで任意のフィールドを組み合わせられる状態は避けるべきです。両方の型を `pub` に変更し、`NodeContext` は既存コンストラクタ、`CodingAgentOpenContext` は追加したコンストラクタへ構築を集約しました。

ソース: [`model.mbt`](../../mbt/package/moon-agent-graph/src/core/model.mbt)、[`coding_agent_contract.mbt`](../../mbt/package/moon-agent-graph/src/core/coding_agent_contract.mbt)

### P1: `admiral.Context` はstructリテラルで正規化を回避できる

`Context` はフラグ、値、値の出所、設定、ネストしたサブコマンドを組み合わせています。`pub(all)` のstructリテラルでは、既存コンストラクタが行う永続Mapと読み取り専用配列への変換を回避できます。型を `pub` に変更し、ドキュメント例と外部コマンドテストでも使用されている `Context::Context` を正規の構築経路として維持しました。

ソース: [`types.mbt`](../../mbt/package/admiral/src/types.mbt)

### P1: SDKプロトコルの出力が呼び出し側で構築可能な入力として公開されている

CodexとOpenCodeのイベント、アイテム、完了済みターン、使用量レコード、SDKエラーは、JSONデコードまたはプロセス実行によって生成されます。呼び出し側はこれらを参照してパターンマッチする必要がありますが、通常のSDK利用で構築する必要はありません。現在の `pub(all)` 宣言は、プロトコルの出力形式をより強い公開互換性の契約にし、ブラックボックステストがデコーダーからは生成されない状態を偽造できるようにしています。これらを読み取り専用の `pub` に変更し、不正または実現不能なプロトコル状態の検証にはデコーダーのフィクスチャかホワイトボックステストを使用してください。

代表的なソース: [`codex-sdk/events.mbt`](../../mbt/package/codex-sdk/src/events.mbt)、[`codex-sdk/items.mbt`](../../mbt/package/codex-sdk/src/items.mbt)、[`opencode-sdk/events.mbt`](../../mbt/package/opencode-sdk/src/events.mbt)

## モジュール別インベントリ

| モジュール                      |    合計 | `pub(all)` を維持 | 既存の構築経路 | 構築経路を追加 | 読み取り専用のみ |
| ------------------------------- | ------: | ----------------: | -------------: | -------------: | ---------------: |
| `totto2727/any-collection`      |       2 |                 0 |              2 |              0 |                0 |
| `totto2727/agent-cli-sdk`       |       4 |                 0 |              1 |              0 |                3 |
| `totto2727/admiral`             |       5 |                 0 |              3 |              1 |                1 |
| `totto2727/codex-sdk`           |      40 |                 7 |              3 |              0 |               30 |
| `totto2727/lens`                |       8 |                 1 |              0 |              0 |                7 |
| `totto2727/moon-agent-graph`    |      50 |                 7 |             10 |             15 |               18 |
| `totto2727/opencode-sdk`        |      16 |                 3 |              2 |              0 |               11 |
| `totto2727/opencode-server-sdk` |       1 |                 0 |              0 |              0 |                1 |
| **合計**                        | **126** |            **18** |         **21** |         **16** |           **71** |

### `totto2727/any-collection`

- 実装を簡略化するため、各ラッパーの `map` フィールドへの直接アクセスを意図された例外として許容します。README、テスト、外部サンプルでは `contains`、`remove`、`length`、`is_empty` などの内部Map操作を使用しています。フィールドは公開のままとし、`AnyMutableMap` では参照先の `Map` を直接変更することも許容します。
- `AnyMutableMap` を `pub` に変更し、既存のコンストラクタを維持します。読み取り専用の `pub struct` でも非privateフィールドにはドット構文でアクセスできるため、許容された内部Map操作を呼ぶために `pub(all)` は必要ありません。
- `AnyImmutableHashMap` を `pub` に変更し、既存のエントリベースのコンストラクタを維持します。追加の `from_hash_map` コンストラクタは不要です。永続 `HashMap` 操作の結果を再ラップする必要がある場合は、structリテラルより不便であっても、そのエントリを既存コンストラクタへ渡せます。

### `totto2727/agent-cli-sdk`

- `pub` に変更し、既存のコンストラクタを維持: `Invocation`
- 読み取り専用の `pub` に変更: `JsonLine`、`RunResult`、`AgentCliError`
- `JsonLine` と `RunResult` はプロセスの出力であり、`AgentCliError` はプロトコルリーダーによって送出されます。

### `totto2727/admiral`

- `pub` に変更し、既存のコンストラクタまたはファクトリを維持: `command` 経由の `CommandDef`、`cli` 経由の `CliApp`、`Context::Context` 経由の `Context`
- 読み取り専用の `pub` に変更: `OptionType`
- `pub` に変更し、コールバック境界用の小さな公開コンストラクタまたはヘルパーを追加: `ConfigLoadFailure`。外部の `load_config` 実装には、このエラーを送出するためのサポートされた手段が必要ですが、将来追加されるすべてのバリアントへ無制限にアクセスできる必要はありません。

### `totto2727/codex-sdk`

- 呼び出し側が意図的に構築する入力enumであるため `pub(all)` を維持: `CodexConfigValue`、`ApprovalMode`、`SandboxMode`、`ModelReasoningEffort`、`WebSearchMode`、`UserInput`、`Input`
- `pub` に変更し、既存のコンストラクタを維持: `CodexOptions`、`ThreadOptions`、`TurnOptions`
- 読み取り専用の `pub` に変更: `Turn`、`ThreadStartedEvent`、`TurnStartedEvent`、`Usage`、`TurnCompletedEvent`、`ThreadError`、`TurnFailedEvent`、`ItemStartedEvent`、`ItemUpdatedEvent`、`ItemCompletedEvent`、`ThreadErrorEvent`、`ThreadEvent`、`CommandExecutionStatus`、`CommandExecutionItem`、`PatchChangeKind`、`FileUpdateChange`、`PatchApplyStatus`、`FileChangeItem`、`McpToolCallStatus`、`McpToolCallResult`、`McpToolCallError`、`McpToolCallItem`、`AgentMessageItem`、`ReasoningItem`、`WebSearchItem`、`ErrorItem`、`TodoItem`、`TodoListItem`、`ThreadItem`、`CodexSdkError`
- 読み取り専用候補30件は、すべてSDKから返されるか送出される型です。テストで直接構築されていることは、プロダクションAPIとして必要であることを意味しません。

### `totto2727/lens`

- 呼び出し側がエンコードモードを意図的に選択するため `pub(all)` を維持: `NullishEncodeMode`
- 読み取り専用の `pub` に変更: `JsonKind`、`IssueCode`、`Issue`、`LensError`、`JsonBuildIssueCode`、`JsonBuildIssue`、`JsonBuildError`
- この7つの型は、Lensの参照、デコード、構築によって生成される失敗を表します。`pub` でもパターンマッチは可能であり、外部から構築する必要はありません。

### `totto2727/moon-agent-graph`

- すべてのバリアントが呼び出し側の選択を意図した入力enumであるため `pub(all)` を維持: `Route`、`NodeKind`、`ArtifactKind`、`CodingAgentStatus`、`ApprovalPolicy`、`NetworkPolicy`、`ResourceScope`
- `pub` に変更し、既存のコンストラクタまたはファクトリを維持: `EventSink`、`NodeContext`、`Node`、`DeclaredRouteMetadata`、`DeclaredRoute`、`RouterMetadata`、`Router`、`RunOptions`、`CodexAgentOptions`、`OpenCodeAgentOptions`
- `pub` に変更し、コンストラクタまたは限定ファクトリを追加: `NodeMetadata`、`Artifact`、`NodeOutput`、`NodeCompletion`、`GraphEvent`、`Reducer`、`WorkspaceRef`、`CodingAgentRequest`、`CodingAgentResponse`、`CodingAgentOpenContext`、`CodingAgent`、`CodingAgentNodeSpec`、`LlmNodeSpec`、`WorkflowState`、`WorkflowPatch`
- 読み取り専用の `pub` に変更: `GraphBuildError`、`GraphValidationError`、`RunFailure`、`GraphRuntimeError`、`CompiledNodeSnapshot`、`CompiledGraphSnapshot`、`IdError`、`ResourceStoreError`、`RunConfigurationError`、`RunResult`、`CodexAdapterError`、`OpenCodeAdapterError`、`ScriptedNodeCall`、`ScriptedRouterCall`、`RecordingReducerCall`、`FakeCodingAgentOpenCall`、`FakeCodingAgentRequestCall`、`NativeTestHelperError`
- `GraphEvent` は型自体を読み取り専用にし、一部の実行イベントとリソースライフサイクルイベントだけを限定ファクトリで公開します。
- `testing` 配下の呼び出し記録structはアクセサーの出力です。テストはこれらを読み取る必要がありますが、構築または変更する必要はありません。
- `WorkflowState` と `WorkflowPatch` はE2E支援コードにあり、テストから直接構築されています。これらのリテラルを明示的なE2Eファクトリに置き換え、テストの利便性によってプロダクションの可視性を決めないでください。

### `totto2727/opencode-sdk`

- 呼び出し側が意図的に構築する入力enumであるため `pub(all)` を維持: `OpenCodeConfigValue`、`UserInput`、`Input`
- `pub` に変更し、既存のコンストラクタを維持: `OpenCodeOptions`、`ThreadOptions`
- 読み取り専用の `pub` に変更: `Turn`、`TextEvent`、`ReasoningEvent`、`ToolUseStatus`、`ToolUseEvent`、`StepStartEvent`、`Usage`、`StepFinishEvent`、`ThreadErrorEvent`、`ThreadEvent`、`OpenCodeSdkError`
- イベントとエラーはデコーダーまたはプロセスの出力です。ブラックボックステストでは、生の値を構築するのではなくデコード処理を実行すべきです。

### `totto2727/opencode-server-sdk`

- `ServerError` を読み取り専用の `pub` に変更します。この型はサーバー起動、準備完了の解析、プロセス終了、クリーンアップ処理によって送出されるため、呼び出し側は参照するだけで十分です。

## 推奨する実装順序

1. 直接的な検証回避を最初に閉じる: `RunOptions`、`Context`、`NodeContext`、`CodingAgentOpenContext`
2. すでにコンストラクタまたはファクトリを持つstructを変更する: オプションstruct、エージェントアダプターのオプション、Mapラッパー、グラフのルートメタデータ、Node/Routerラッパー
3. 不足している16件の構築APIを追加し、プロダクションの呼び出し箇所を移行してから可視性を縮小する。
4. プロトコル出力、グラフのイベント・結果・スナップショット、診断レコード、suberror、テスト用の呼び出し記録を読み取り専用の `pub` に変更する。
5. 同一パッケージで無効状態を扱うテストを `_wbtest.mbt` へ移動し、パッケージをまたぐテストには用途を限定したテスト用ファクトリを使用する。
6. 公開済みモジュールでは、実際に可視性を変更する前の互換期間として `#visibility(change_to="readonly", "Use the package constructor or factory.")` を適用する。

## 実装時に想定する検証

このレポートでは、大規模なテスト追加を推奨しません。モジュールごとに必要十分な最小限の検証は次のとおりです。

1. 可視性と呼び出し箇所を移行した後に `vp run mbt:check` を実行する。
2. 変更したモジュール境界の影響を受ける既存のMoonBitテストを実行する。
3. 読み取り専用フィールドの参照とenumのパターンマッチが引き続き機能し、生の構築が失敗することを、小さな外部コンシューマーまたはブラックボックステストでコンパイルして確認する。
4. `RunOptions` と新しい検証付きコンストラクタについて、不正入力を扱う焦点を絞った回帰テストを1件ずつ維持する。

適用後は対象126件を再集計し、意図した入力enum 18件だけが `pub(all)` のままであることを確認しました。あわせて `vp run mbt:check` と、設定済みの両ターゲットに対する既存MoonBitテストを実行しました。
