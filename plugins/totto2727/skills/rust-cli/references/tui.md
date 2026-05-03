# Rust CLI — UI レイヤ詳細 (軽量 CLI / 高度な宣言的 UI)

CLI に組み込む UI を 2 レイヤに整理する:

- **軽量 CLI**: 入力受付 + 進捗表示 + ログ出力で完結するもの。単体機能クレートを直接組み合わせる。
- **高度な宣言的 UI**: フル画面ダッシュボード・複数画面遷移・大規模状態管理。`tui-realm` で構築する。

中間に位置する「宣言的だが軽量」な選択肢 (例: React 風 TUI フレームワーク) は本スキルでは採用しない。

## レイヤ早見

| レイヤ          | 用途                                                        | 推奨                                                                                   | 特徴                                                                                 |
| --------------- | ----------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 軽量 CLI        | 引数解析・プロンプト・進捗バー / スピナー・ログ出力・色付け | `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + 標準 `println!` の組合せ | 各クレートが独立した薄い責務を持ち、必要なものだけを直接呼ぶ。フレームワーク化しない |
| 高度な宣言的 UI | フル画面ダッシュボード・複数画面遷移                        | `tui-realm`                                                                            | Component + Message/Update の Elm Architecture                                       |

「どちらを選ぶか」の判断基準は **UI 自体が状態機械として複雑になるか**。
入力 + ログを流すだけなら軽量 CLI で止める (シンプルな入出力に `tui-realm` は過剰)。

## 軽量 CLI: `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + 標準 `println!`

それぞれが単一責務の小さなクレートで、CLI の必要なところに直接呼び出す形で組み合わせる。「TUI フレームワーク」ではない。

### 役割分担

| クレート / 機能               | 役割                                                    | 典型呼び出し例                                               |
| ----------------------------- | ------------------------------------------------------- | ------------------------------------------------------------ |
| `clap`                        | 引数 / サブコマンド / env                               | `Cli::parse()` (`derive` でフラグを宣言的に)                 |
| `tracing`                     | **構造化ログ** (機械可読)                               | `tracing::info!(...)` + `tracing_subscriber::fmt()` 初期化   |
| 標準 `println!` / `eprintln!` | **単純 stdout / stderr** (人間向け / プログラム間 pipe) | `println!("...")` / `eprintln!("...")`                       |
| `owo-colors`                  | **色付け** (装飾出力)                                   | `"warning".yellow()` / `"ok".green()` (`OwoColorize` trait)  |
| `inquire`                     | 単発プロンプト                                          | `Select::new(...).prompt()?` / `Confirm::new(...).prompt()?` |
| `indicatif`                   | プログレスバー / スピナー                               | `ProgressBar::new(n)` / `ProgressBar::new_spinner()`         |

#### 出力責務の分担原則

- **構造化ログ (`tracing`)**: 機械可読 / 監視 / 後追い解析が必要なイベント。`tracing_subscriber` で出力先・フォーマット・filter を一元設定する
- **単純 stdout / stderr (標準機能)**: コマンドの主出力 (パイプの上流として後段に流すデータ) や、ユーザー向けの 1 回限りのテキスト
- **色付け (`owo-colors`)**: 上記の出力に視覚的強調を加える専用レイヤ。`tracing` の filter / `println!` の使い分けとは独立した責務

### `clap` (引数解析)

`derive` マクロで `struct` / `enum` ベースに宣言する。`#[arg(env = "...")]` で env フォールバックを表現できる。サブコマンドは `#[derive(Subcommand)]` enum で分割する。雛形は [../templates/main.rs](../templates/main.rs)。

### `tracing` (構造化ログ)

`tracing::info!` / `warn!` / `error!` を埋めて、`main` 起動時に `tracing_subscriber::fmt()` (もしくは `tracing_subscriber::registry()` で複合 layer) を初期化する。フォーマット切り替えは `with_env_filter(EnvFilter::try_from_default_env()...)` 経由で `RUST_LOG` から制御する。**機械可読な構造化ログ専用** で使う (人間向けの単純な stdout 出力や CLI 主出力は標準 `println!` を使う)。

### 標準 `println!` / `eprintln!` (stdout / stderr)

CLI の主出力 (コマンド実行結果) や 1 回限りのテキスト出力には外部クレートを介さず標準機能を直接使う。stderr へは `eprintln!`。pipeline で後段に流すデータは `println!` で stdout、進捗 / メッセージは `eprintln!` で stderr に出すのが原則。

### `owo-colors` (色付け)

`OwoColorize` trait を `use` するだけで、任意の `Display` 実装に `.green()` / `.yellow()` / `.bold()` 等のメソッドが生える。`tracing` のフォーマッタ や `println!` の出力に色を被せる装飾専用レイヤ。色の有効化判定 (`atty` / NO_COLOR 環境変数) は `if_supports_color()` で抑制可能。

### `inquire` (プロンプト)

提供されるウィジェット: `Select`, `MultiSelect`, `Text`, `Password`, `Confirm`, `Editor`, `DateSelect`, `CustomType`, autocomplete 付き Select。バリデーション・ページング・タブ補完が組み込みで提供される。プロンプトを表示する箇所だけで呼び出す。

### `indicatif` (進捗 / スピナー)

- `ProgressBar::new_spinner()` で待機表示用スピナー、`ProgressBar::new(n)` で bounded プログレスバー
- `MultiProgress` で複数バー併走
- `set_style(ProgressStyle::with_template(...))` でテンプレート文字列指定
- `tracing` と併用する場合、`indicatif-log-bridge` 等を介して並走可能だが、本スキルでは「進捗は indicatif、ログは tracing」と用途で分け、必要なら `pb.println("...")` 経由で stderr に書き出す方針

### 並用パターン例

```text
clap で引数を受ける
  → inquire で対話的にデフォルト値を確認
  → indicatif スピナー開始
  → 非同期処理 (tokio + reqwest 等)
  → tracing::info! で要約ログ (構造化ログ、stderr / 任意の subscriber 出力先)
  → indicatif スピナー finish
  → 結果 (取得したデータ / 整形済み出力) を println! で stdout に書き出す
    (パイプ後段に流せるように)。ヒューマン向けメッセージは eprintln!、
    強調が要る箇所は owo-colors で `.green()` / `.bold()` などを被せる
```

このレイヤで完結するなら `tui-realm` を持ち込まない。

### 例外: 複雑な最終アウトプットでの部分的な `tui-realm` 採用

軽量 CLI として全体を組んでいる途中で、最終アウトプットとして複雑な表 / 多列リスト / 構造化されたビューが必要になる場合がある。このときは**その出力部分だけ `tui-realm` を呼び出す**部分採用パターンを許容する (UI 全体を `tui-realm` に切り替える必要はない)。

- 適用条件: 出力が `println!` ベースの単純な行ベース整形では読みにくい程度に複雑 (列数が多い / セル幅調整が要る / フィルタリングが要る等)
- スコープ: 最終アウトプットを描画する関数だけに `tui-realm` の Component を作って呼び出し、それ以外 (引数解析 / 進捗 / ログ) は引き続き軽量 CLI スタックで進める
- 区別: ループする画面遷移 / 入力イベント駆動が要るなら部分採用ではなく「高度な宣言的 UI」モードへの切り替えを検討する

## 高度な宣言的 UI: `tui-realm`

React + Elm 折衷の状態管理を備えた TUI フレームワーク ("Realm" は React と Elm の合成語に由来)。下層の描画ライブラリとして `ratatui` を内部利用するが、本スキルでは原則として `tui-realm` の API のみを使う (`ratatui` を直接叩く設計は採用しない)。

### 構成要素

- **Component**: 再利用可能な UI 部品 (props / state を持つ)
- **Application**: Component を束ねる
- **Update / Message**: Elm の Update 関数相当でメッセージ駆動
- **Event**: 入力イベント

### 採用条件

以下のいずれかに当てはまる場合に検討する:

- フル画面ダッシュボードや複数ペイン構成が必要
- 画面遷移・ウィザード等で大規模な状態機械が要る
- 入力イベントとレンダリングをループで回す必要がある

軽量 CLI で済む規模なら採用しない (オーバーエンジニアリング)。

## 選択指針 (フローチャート的)

1. 引数受付 + ログ流し + 単発プロンプト + 進捗バー / スピナー + 色付き出力で足りる？
   → **軽量 CLI** (`clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + 標準 `println!`)
2. フル画面 / 多画面遷移 / 大規模状態管理が必要？
   → **高度な宣言的 UI** (`tui-realm`)

迷ったら軽量 CLI から始め、UI の状態管理が肥大化してから `tui-realm` に切り替える。

## 関連リソース

- [clap](https://github.com/clap-rs/clap)
- [tracing](https://github.com/tokio-rs/tracing)
- [owo-colors](https://github.com/jam1garner/owo-colors)
- [inquire](https://github.com/mikaelmello/inquire)
- [indicatif](https://github.com/console-rs/indicatif)
- [tui-realm](https://github.com/veeso/tui-realm)
