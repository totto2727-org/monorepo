---
name: rust-cli
description: >-
  This skill should be used when designing or implementing async CLI tools in Rust,
  selecting Rust crates for CLI work (argument parsing, HTTP, JSON/Schema, error handling,
  filesystem, dates, logging, TUI/spinner/prompt), or porting existing Effect-based / Node CLIs to Rust.
  Common triggers: "Rust CLI", "RustでCLI", "clap", "tokio", "reqwest", "tui-realm",
  "inquire", "indicatif", "ライブラリ選定", "技術選定 Rust", "Effect から Rust 移植".
  Do NOT use for: production-grade architecture review (use code-reviewer),
  generic Rust questions unrelated to CLI scope, or non-async sync-only CLI design.
metadata:
  author: totto2727
  version: 1.0.0
---

# Rust CLI — 非同期 Rust CLI 技術選定マップ

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Context-aware Selection**（要件に応じてレイヤを動的に選択）

非同期 Rust で CLI を新規実装する／Effect ベースの既存 CLI を移植する際の、
クレート選定と最小構成セットを提示する。判断の前提は **tokio + clap + reqwest + serde** の標準スタック。

## スキル発火時の出力

ユーザーの要件を聞き取った上で、以下のいずれか or 組み合わせを返す:

1. **「レイヤ別早見表」と「UI レイヤ選択 (軽量 CLI / 高度な宣言的 UI の二択)」の表を提示**（迷っている場合の最初のレスポンス）
2. **`references/libraries.md` の該当カテゴリを引用**（特定機能のクレート比較を求められた場合）
3. **`templates/` のスターターを案内**（プロジェクト雛形が欲しい場合）
4. **JS/Effect ↔ Rust の置換早見**（移植作業の場合、`references/libraries.md` 末尾参照）

新規 Rust 質問でも CLI に関係しない場合は **発火しない**。

## 基本方針

- **非同期前提**: `tokio` をデフォルトランタイムにする。同期処理だけで足りるなら blocking 版を選ぶ
- **エラー戦略**: ライブラリ層 / アプリ層ともに `thiserror` + `miette` の単一スタックで設計する。各エラー型に `#[derive(thiserror::Error, miette::Diagnostic)]` を併用し、`#[diagnostic(code(...), help(...))]` でリッチな診断レポートを付与する。アプリ層は `miette::Result<T>` を返し、外部クレートの `Result` は `.into_diagnostic()` で取り込み、`.wrap_err(...)` で意味的 context を積む
- **HTTP**: `reqwest::Client` をプロセス全体で `Arc` 共有してコネクションを再利用する
- **CLI フラグ**: `clap` derive。`#[arg(env = "...")]` で env フォールバックを宣言的に表現する
- **UI レイヤ選定 (二択)**:
  - **軽量 CLI** (入力受付 + ログ出力 + 進捗表示が中心): `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` の単体機能クレートを組み合わせる。出力責務は明確に分ける — **構造化ログは `tracing`、単純 stdout は標準機能 (`println!` / `eprintln!`)、色付けは `owo-colors`**。これで足りるなら `tui-realm` を持ち込まない (過剰)
  - **高度な宣言的 UI** (複数画面・大規模状態・ダッシュボード等): `tui-realm` (Elm Architecture) に統一。下層描画ライブラリ (`ratatui`) は transitive dep として入るが、原則として `tui-realm` の API のみで実装する
- **コードは決定的、言語の解釈は非決定的** — バリデーション・スキーマ検査は serde/garde に任せる

## レイヤ別早見表（必須カテゴリのみ）

| カテゴリ     | 推奨クレート                     | 補足                                                                                |
| ------------ | -------------------------------- | ----------------------------------------------------------------------------------- |
| ランタイム   | `tokio` (`full`)                 | `#[tokio::main]`                                                                    |
| 引数解析     | `clap` (`derive`)                | env フォールバック・サブコマンドを宣言的に                                          |
| HTTP         | `reqwest` (`json`, `rustls-tls`) | `Arc<Client>` を共有                                                                |
| シリアライズ | `serde` + `serde_json`           | derive                                                                              |
| スキーマ検証 | `garde` (任意)                   | serde で型一致は保証、値域は garde                                                  |
| エラー型     | `thiserror` + `miette`           | `#[derive(thiserror::Error, miette::Diagnostic)]` を併用                            |
| エラー集約   | `miette` (`Result` / `Report`)   | アプリ層は `miette::Result<T>`、外部 `Result` は `.into_diagnostic().wrap_err(...)` |
| ファイル I/O | `tokio::fs`                      | mkdir/read/write/symlink 等                                                         |
| 子プロセス   | `tokio::process::Command`        | git CLI 駆動などはこれが最短                                                        |
| 日付         | `jiff`                           | TZ-aware/DST 安全（chrono は legacy）                                               |
| ログ         | `tracing` + `tracing-subscriber` | 単発 println で済むなら不要                                                         |

詳細は [references/libraries.md](./references/libraries.md) — JS/Effect 側との **完全対応表**（FS/Path/並行/テスト/git/glob まで）。

## UI レイヤ選択 (軽量 CLI / 高度な宣言的 UI の二択)

要件に応じて 2 レイヤから選ぶ。**入力 + ログ + 進捗で済むなら軽量 CLI で止める** (`tui-realm` は過剰)。

| レイヤ          | 用途                                                    | 推奨スタック                                                                                                                                                                                                          |
| --------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 軽量 CLI        | 引数解析・単発プロンプト・進捗バー / スピナー・ログ出力 | `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` を**単体機能クレートとして組み合わせる** (フレームワーク化しない)。出力責務は **ログ=`tracing` / stdout=標準機能 / 色付け=`owo-colors`** で明確に分担する |
| 高度な宣言的 UI | フル画面ダッシュボード・複数画面遷移・大規模状態管理    | `tui-realm` (Elm Architecture)                                                                                                                                                                                        |

軽量 CLI 側は責務ごとに独立した薄いクレートを直接呼ぶ設計。`tui-realm` を持ち込むのは UI 自体が状態機械として複雑になるケースに限定する。

詳細・コード例は [references/tui.md](./references/tui.md)。

## スターター・テンプレート

最小プロジェクトをテンプレートから始める:

- [templates/Cargo.toml](./templates/Cargo.toml) — 推奨依存セット
- [templates/main.rs](./templates/main.rs) — `clap` + `tokio` + `reqwest` + `thiserror` + `miette` の最小例

## 選定の判断手順

1. **同期で済むか確認** — 並行 I/O が無いなら blocking 版（`reqwest::blocking`）で十分
2. **UI レイヤを決める** — 軽量 CLI (clap + tracing + inquire + indicatif + owo-colors + 標準 `println!`) で足りるか、それとも高度な宣言的 UI (tui-realm) が要るか
3. **エラー設計を決める** — ライブラリ・アプリ層共通で `thiserror` + `miette::Diagnostic` derive を使い、アプリ層は `miette::Result<T>` で `?` 伝播。外部クレートの `Result` は `.into_diagnostic().wrap_err(...)` で取り込む
4. **既存 Effect/Node CLI 移植の場合** — まず引数解析の `Option<T>` フラグと env フォールバックを `clap` の derive で書き直すと、`auth.ts` 的な手書き分岐が消える

## トラブルシューティング

### サブコマンドが多すぎて `clap` 定義が肥大化する

derive の `#[derive(Subcommand)]` を enum で分割し、サブモジュールごとにファイル分け。
構造は [templates/main.rs](./templates/main.rs) を起点に拡張する。

### `thiserror` + `miette` の役割分担

- **ライブラリ／サービス層**: `#[derive(thiserror::Error, miette::Diagnostic)]` を併用。`thiserror` は呼び出し側が `match` 可能な型付き enum を提供し、`miette` は `#[diagnostic(code(...), help(...))]` で診断メタデータを付与する
- **アプリ層 / `main`**: `miette::Result<()>` (= `Result<(), miette::Report>`) で集約。`?` で `miette::Diagnostic` 実装型を直接吸い上げる
- **外部クレートの `Result`**: `.into_diagnostic()` (`miette::IntoDiagnostic`) で `Report` 化してから `?` 伝播
- **意味的 context**: ドメイン情報 (リクエスト ID・対象パス等) は `.wrap_err(...)` / `.wrap_err_with(\|\| format!("..."))` (`miette::WrapErr`) で積む
- **ソース位置 / バックトレース**: `RUST_BACKTRACE=1` で `miette::Report` がバックトレースを表示。`?` 単位の自動位置注入はしない (関数単位の `wrap_err` で意味的に追跡する方針)
- **エンドユーザー向け表示**: `main` 起動時に `miette::set_panic_hook()` を呼ぶか、`Cargo.toml` で `miette = { version = "...", features = ["fancy"] }` を有効化することでカラー付きの診断レポートが出力される

## 発火例

### Should trigger（発火させたい）

- 「Rust で非同期 CLI を作りたい。clap と tokio と reqwest の組み合わせで雛形が欲しい」
- 「Effect で書いた CLI を Rust に移植したい。Schema の置き換えはどうすれば？」
- 「Rust CLI でスピナー / 進捗バーを出したい。indicatif の使い方を教えて」
- 「Rust CLI でフル画面ダッシュボードを書きたい。tui-realm の構成は？」
- 「Rust CLI のエラー設計を miette + thiserror で組みたい」

### Should NOT trigger（発火させない）

- 「Rust の所有権について教えて」 → CLI 文脈ではない
- 「Rust の actix-web で API サーバーを作りたい」 → サーバー実装、CLI ではない
- 「この Rust コードのレビューをお願い」 → `code-reviewer` の責務
- 「Deno で CLI を作りたい」 → `deno-cli-tool` の責務
- 「同期処理だけで済む短い Rust スクリプトを書きたい」 → 非同期 CLI スコープ外（ネガティブトリガーで明示）
