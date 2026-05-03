---
name: rust-cli
description: >-
  This skill should be used when designing or implementing async CLI tools in Rust,
  selecting Rust crates for CLI work (argument parsing, HTTP, JSON/Schema, error handling,
  filesystem, dates, logging, TUI/spinner/prompt), or porting existing Effect-based / Node CLIs to Rust.
  Common triggers: "Rust CLI", "RustでCLI", "clap", "tokio", "reqwest", "iocraft",
  "ratatui", "ライブラリ選定", "技術選定 Rust", "Effect から Rust 移植".
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

1. **「レイヤ別早見表」と「TUI レイヤ選択」の表を提示**（迷っている場合の最初のレスポンス）
2. **`references/libraries.md` の該当カテゴリを引用**（特定機能のクレート比較を求められた場合）
3. **`templates/` のスターターを案内**（プロジェクト雛形が欲しい場合）
4. **JS/Effect ↔ Rust の置換早見**（移植作業の場合、`references/libraries.md` 末尾参照）

新規 Rust 質問でも CLI に関係しない場合は **発火しない**。

## 基本方針

- **非同期前提**: `tokio` をデフォルトランタイムにする。同期処理だけで足りるなら blocking 版を選ぶ
- **エラー戦略**: ライブラリ層は `thiserror` で variant 定義、アプリ層は `anyhow` で集約、`#[hooq(anyhow)]` で `?` に位置情報を自動注入する
- **HTTP**: `reqwest::Client` をプロセス全体で `Arc` 共有してコネクションを再利用する
- **CLI フラグ**: `clap` derive。`#[arg(env = "...")]` で env フォールバックを宣言的に表現する
- **TUI**: 単発プロンプト/スピナー止まりなら `inquire` + `indicatif`、宣言的 UI なら `iocraft`、フル画面 Elm なら `tui-realm` + `ratatui`
- **コードは決定的、言語の解釈は非決定的** — バリデーション・スキーマ検査は serde/garde に任せる

## レイヤ別早見表（必須カテゴリのみ）

| カテゴリ     | 推奨クレート                     | 補足                                       |
| ------------ | -------------------------------- | ------------------------------------------ |
| ランタイム   | `tokio` (`full`)                 | `#[tokio::main]`                           |
| 引数解析     | `clap` (`derive`)                | env フォールバック・サブコマンドを宣言的に |
| HTTP         | `reqwest` (`json`, `rustls-tls`) | `Arc<Client>` を共有                       |
| シリアライズ | `serde` + `serde_json`           | derive                                     |
| スキーマ検証 | `garde` (任意)                   | serde で型一致は保証、値域は garde         |
| エラー型     | `thiserror`                      | サービスごとに enum                        |
| エラー集約   | `anyhow`                         | アプリ層で `?` 伝播 + `.with_context()`    |
| エラー位置   | `hooq` (`#[hooq(anyhow)]`)       | `?` ごとにファイル/行/列/式を自動注入      |
| ファイル I/O | `tokio::fs`                      | mkdir/read/write/symlink 等                |
| 子プロセス   | `tokio::process::Command`        | git CLI 駆動などはこれが最短               |
| 日付         | `jiff`                           | TZ-aware/DST 安全（chrono は legacy）      |
| ログ         | `tracing` + `tracing-subscriber` | 単発 println で済むなら不要                |

詳細は [references/libraries.md](./references/libraries.md) — JS/Effect 側との **完全対応表**（FS/Path/並行/テスト/git/glob まで）。

## TUI / 対話 UI のレイヤ選択

要件に応じて 3 レイヤから選ぶ。**フル TUI が要らないなら 1 で止める**。

| レイヤ                        | 用途                           | 推奨                     |
| ----------------------------- | ------------------------------ | ------------------------ |
| L1: 単発プロンプト＋スピナー  | y/n 確認・選択肢・進捗         | `inquire` + `indicatif`  |
| L2: 宣言的（React-like）      | Ink 風コンポーネント／フォーム | `iocraft`                |
| L3: フル画面 Elm Architecture | ダッシュボード                 | `tui-realm` on `ratatui` |

iocraft はランタイム非依存（依存は `crossterm` + `futures` + `taffy`）で **tokio と直接組み合わせ可能**。
スピナーはビルトイン非対応だが `use_state` + `use_future` で 10 行で書ける。

詳細・コード例は [references/tui.md](./references/tui.md)。

## スターター・テンプレート

最小プロジェクトをテンプレートから始める:

- [templates/Cargo.toml](./templates/Cargo.toml) — 推奨依存セット
- [templates/main.rs](./templates/main.rs) — `clap` + `tokio` + `reqwest` + `anyhow` + `thiserror` + `hooq` の最小例
- [templates/spinner.rs](./templates/spinner.rs) — iocraft で書く再利用 Spinner コンポーネント

## 選定の判断手順

1. **同期で済むか確認** — 並行 I/O が無いなら blocking 版（`reqwest::blocking`）で十分
2. **TUI のレイヤを決める** — L1 で足りるか／L2 で宣言的に書きたいか／L3 でフル画面か
3. **エラー設計を決める** — ライブラリ層は `thiserror` で型付き enum、アプリ層は `anyhow` で集約、`#[hooq(anyhow)]` で位置情報を自動付与する
4. **既存 Effect/Node CLI 移植の場合** — まず引数解析の `Option<T>` フラグと env フォールバックを `clap` の derive で書き直すと、`auth.ts` 的な手書き分岐が消える

## トラブルシューティング

### `iocraft` と `reqwest` でランタイム競合する

iocraft の examples は `smol::block_on` を使うが、`render_loop()` は単なる `Future` のため
`#[tokio::main]` 配下で `.await` してよい。`use_future` 内も `tokio::time::sleep` で問題ない。

### サブコマンドが多すぎて `clap` 定義が肥大化する

derive の `#[derive(Subcommand)]` を enum で分割し、サブモジュールごとにファイル分け。
構造は [templates/main.rs](./templates/main.rs) を起点に拡張する。

### `thiserror` / `anyhow` / `hooq` の役割分担

- **ライブラリ／サービス層**: `thiserror` で型付き enum（呼び出し側が `match` 可能、テストしやすい）
- **アプリ層 / `main`**: `anyhow::Result<()>` で集約。`?` で `thiserror` enum を吸い上げる
- **位置情報**: `#[hooq(anyhow)]` を関数に付けて、各 `?` の前に `.with_context(\|\| "[file:line:col] expr")` を自動注入
- **意味的 context**: ドメイン情報（リクエスト ID・対象パス等）は `.with_context(\|\| format!("..."))` を手書きで追加（hooq の自動付与と併用）

### `hooq` の付与漏れを防ぐ

- `#[hooq(anyhow)]` は関数単位の opt-in。新規関数で付け忘れると位置情報が抜ける
- レビュー時に `?` を含む関数で属性が付いているかを確認する
- MSRV 1.88 以上が必要（`proc_macro::Span::line` 利用）

## 発火例

### Should trigger（発火させたい）

- 「Rust で非同期 CLI を作りたい。clap と tokio と reqwest の組み合わせで雛形が欲しい」
- 「Effect で書いた CLI を Rust に移植したい。Schema の置き換えはどうすれば？」
- 「Rust CLI でスピナーを出したい。indicatif と iocraft どっちがいい？」
- 「ratatui と tui-realm の違いは？ Elm Architecture で書きたい」
- 「Rust の HTTP クライアントクレート、reqwest 以外の選択肢は？」

### Should NOT trigger（発火させない）

- 「Rust の所有権について教えて」 → CLI 文脈ではない
- 「Rust の actix-web で API サーバーを作りたい」 → サーバー実装、CLI ではない
- 「この Rust コードのレビューをお願い」 → `code-reviewer` の責務
- 「Deno で CLI を作りたい」 → `deno-cli-tool` の責務
- 「同期処理だけで済む短い Rust スクリプトを書きたい」 → 非同期 CLI スコープ外（ネガティブトリガーで明示）
