# Rust CLI — UI レイヤ詳細 (軽量 CLI / 高度な宣言的 UI)

CLI に組み込む UI を 2 レイヤに整理する:

- **軽量 CLI**: 入力受付 + 進捗表示 + ログ出力で完結するもの。単体機能クレートを直接組み合わせる。
- **高度な宣言的 UI**: フル画面ダッシュボード・複数画面遷移・大規模状態管理。`tui-realm` で構築する。

中間に位置する「宣言的だが軽量」な選択肢 (例: React 風 TUI フレームワーク) は本スキルでは採用しない。

## レイヤ早見

| レイヤ          | 用途                                                | 推奨                                                  | 特徴                                                                                 |
| --------------- | --------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 軽量 CLI        | 引数解析・プロンプト・進捗バー / スピナー・ログ出力 | `clap` + `tracing` + `inquire` + `indicatif` の組合せ | 各クレートが独立した薄い責務を持ち、必要なものだけを直接呼ぶ。フレームワーク化しない |
| 高度な宣言的 UI | フル画面ダッシュボード・複数画面遷移                | `tui-realm` on `ratatui`                              | Component + Message/Update の Elm Architecture                                       |

「どちらを選ぶか」の判断基準は **UI 自体が状態機械として複雑になるか**。
入力 + ログを流すだけなら軽量 CLI で止める (シンプルな入出力に `tui-realm` は過剰)。

## 軽量 CLI: `clap` + `tracing` + `inquire` + `indicatif`

それぞれが単一責務の小さなクレートで、CLI の必要なところに直接呼び出す形で組み合わせる。「TUI フレームワーク」ではない。

### 役割分担

| クレート    | 役割                      | 典型呼び出し例                                               |
| ----------- | ------------------------- | ------------------------------------------------------------ |
| `clap`      | 引数 / サブコマンド / env | `Cli::parse()` (`derive` でフラグを宣言的に)                 |
| `tracing`   | 構造化ログ出力            | `tracing::info!(...)` + `tracing_subscriber::fmt()` 初期化   |
| `inquire`   | 単発プロンプト            | `Select::new(...).prompt()?` / `Confirm::new(...).prompt()?` |
| `indicatif` | プログレスバー / スピナー | `ProgressBar::new(n)` / `ProgressBar::new_spinner()`         |

### `clap` (引数解析)

`derive` マクロで `struct` / `enum` ベースに宣言する。`#[arg(env = "...")]` で env フォールバックを表現できる。サブコマンドは `#[derive(Subcommand)]` enum で分割する。雛形は [../templates/main.rs](../templates/main.rs)。

### `tracing` (ログ)

`tracing::info!` / `warn!` / `error!` を埋めて、`main` 起動時に `tracing_subscriber::fmt()` (もしくは `tracing_subscriber::registry()` で複合 layer) を初期化する。フォーマット切り替えは `with_env_filter(EnvFilter::try_from_default_env()...)` 経由で `RUST_LOG` から制御する。

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
  → tracing::info! で要約ログ
  → indicatif スピナー finish
```

このレイヤで完結するなら `tui-realm` を持ち込まない。

## 高度な宣言的 UI: `tui-realm` on `ratatui`

`ratatui` は immediate-mode の低レベル描画ライブラリ。これに React + Elm 折衷の状態管理を被せたのが `tui-realm` ("Realm" = **R**eact + **E**lm)。

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

1. 引数受付 + ログ流し + 単発プロンプト + 進捗バー / スピナーで足りる？
   → **軽量 CLI** (`clap` + `tracing` + `inquire` + `indicatif`)
2. フル画面 / 多画面遷移 / 大規模状態管理が必要？
   → **高度な宣言的 UI** (`tui-realm` on `ratatui`)

迷ったら軽量 CLI から始め、UI の状態管理が肥大化してから `tui-realm` に切り替える。

## 関連リソース

- [clap](https://github.com/clap-rs/clap)
- [tracing](https://github.com/tokio-rs/tracing)
- [inquire](https://github.com/mikaelmello/inquire)
- [indicatif](https://github.com/console-rs/indicatif)
- [tui-realm](https://github.com/veeso/tui-realm)
- [ratatui](https://ratatui.rs/)
