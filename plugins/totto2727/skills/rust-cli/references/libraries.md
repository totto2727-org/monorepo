# Rust CLI Libraries — JS/Effect ↔ Rust 完全対応表

非同期 Rust で CLI を実装する際の、機能カテゴリごとの推奨クレート。
JS / Effect 側の対応物を併記し、移植の見通しを立てやすくする。

## 表の見方

- **推奨**: 採用するクレート (本スキルでは候補を絞り、代替は記載しない)
- 非同期前提（tokio）。同期版が必要な場合は各クレートの blocking feature を参照

## コア（必須カテゴリ）

| 機能                   | 用途                           | JS / Effect 側                                            | Rust 推奨                                                                          |
| ---------------------- | ------------------------------ | --------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| ランタイム             | task / 並行 I/O                | `@effect/platform-node` `NodeRuntime` + `Effect.gen`      | `tokio` (`full` features)                                                          |
| 引数解析               | サブコマンド・フラグ・ヘルプ   | `effect/unstable/cli` (`Command`/`Flag`)                  | `clap` (`derive`)                                                                  |
| HTTP クライアント      | REST API（JSON/binary/header） | `effect/unstable/http` (`HttpClient` + `FetchHttpClient`) | `reqwest` (`json` + `rustls-tls`)                                                  |
| JSON                   | parse / stringify              | `JSON.*`                                                  | `serde` + `serde_json`                                                             |
| スキーマ検証           | 不明値→型検査                  | `effect` `Schema.decodeUnknownEffect`                     | `serde` derive（型一致） + `garde`（値域）                                         |
| エラー型定義           | タグ付きエラー                 | `Data.TaggedError`                                        | `thiserror` + `miette` (`Diagnostic` derive 併用)                                  |
| エラー集約（アプリ層） | `?` 伝播 + context             | `Effect` の chain                                         | `miette::Result<T>` (= `Result<T, miette::Report>`) + `IntoDiagnostic` / `WrapErr` |
| エラー診断レポート     | help / labels / source-spans   | （手書きフォーマット）                                    | `miette` (`#[diagnostic(code, help, ...)]` + `fancy` feature)                      |
| Option / Result        | nullable / 失敗                | `Option`, `Effect`                                        | 標準 `Option<T>` / `Result<T, E>`                                                  |

## I/O・OS

| 機能           | 用途                             | JS / Effect 側                                | Rust 推奨                                 | 補足                                                                     |
| -------------- | -------------------------------- | --------------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------ |
| 非同期ファイル | read/write/mkdir/rm              | `node:fs/promises`                            | `tokio::fs`                               | —                                                                        |
| パス           | join / relative / dirname        | `node:path`                                   | 標準 `std::path`                          | —                                                                        |
| Symlink        | 作成 / 判定                      | `Fs.symlink`, `lstat().isSymbolicLink()`      | `tokio::fs::symlink` + `symlink_metadata` | Windows は `std::os::windows::fs::symlink_dir/file` を使い分ける必要あり |
| 子プロセス     | `git` などの外部コマンド呼び出し | Node `child_process` の execFile（promisify） | `tokio::process::Command`                 | sync 処理は `tokio::task::spawn_blocking` 経由で逃がす                   |
| 環境変数       | API トークン取得                 | `process.env`                                 | 標準 `std::env::var`                      | —                                                                        |
| 一時ファイル   | テスト fixture                   | （手書き）                                    | `tempfile`                                | RAII で自動削除                                                          |
| ファイル排他   | lock-file 同時書き込み防止       | （手書き）                                    | `fd-lock`                                 | —                                                                        |

## 並行・並列

| 機能                 | 用途         | JS / Effect 側                             | Rust 推奨                               |
| -------------------- | ------------ | ------------------------------------------ | --------------------------------------- |
| unbounded concurrent | 並列 I/O     | `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`             |
| 上限付き concurrent  | n 並列に制限 | `Effect.all({ concurrency: n })`           | `stream::iter(...).buffer_unordered(n)` |
| panic 安全な spawn   | エラー分離   | —                                          | `tokio::task::JoinSet`                  |

## データ・フォーマット

| 機能                   | 用途                  | JS / Effect 側                      | Rust 推奨                |
| ---------------------- | --------------------- | ----------------------------------- | ------------------------ |
| YAML                   | frontmatter, config   | （現状未使用）                      | `serde_yml`              |
| TOML                   | config                | （現状未使用）                      | `toml`                   |
| 設定（複数ソース統合） | env + file + CLI 統合 | `JSON.parse(readFile)` + 自前マージ | `figment`                |
| 日付・時刻             | TZ-aware datetime     | `Date`, `effect` DateTime           | `jiff`                   |
| グロブ                 | パターンマッチ        | （手書き）                          | `globset`                |
| ファイル走査           | gitignore 尊重再帰    | 手書き再帰 + `SKIP_DIRS`            | `ignore`（ripgrep 由来） |
| 差分                   | dry-run プレビュー    | （手書き）                          | `similar`                |

## 観測・出力

| 機能        | 用途         | JS / Effect 側 | Rust 推奨                        |
| ----------- | ------------ | -------------- | -------------------------------- |
| 構造化ログ  | 階層付きログ | `Effect.log`   | `tracing` + `tracing-subscriber` |
| 単純 stdout | デバッグ出力 | `Console.log`  | 標準 `println!` / `eprintln!`    |
| 色付け      | 装飾出力     | （現状なし）   | `owo-colors`                     |

## UI レイヤ (軽量 CLI / 高度な宣言的 UI の二択)

[tui.md](./tui.md) も参照。

| レイヤ                | 用途                                | 推奨        |
| --------------------- | ----------------------------------- | ----------- |
| 軽量 (プロンプト)     | select / input / confirm / password | `inquire`   |
| 軽量 (進捗・スピナー) | プログレスバー / 待機表示           | `indicatif` |
| 高度な宣言的 UI       | フル画面ダッシュボード / 多画面遷移 | `tui-realm` |

軽量 CLI 側は **`clap` + `tracing` + `inquire` + `indicatif` を単体機能クレートとして組み合わせる**。これで足りるなら `tui-realm` を持ち込まない (過剰)。

## バージョン管理 / Git

| 機能     | 用途                            | JS / Effect 側                   | Rust 推奨                                     |
| -------- | ------------------------------- | -------------------------------- | --------------------------------------------- |
| Git 操作 | clone / pull / fetch / checkout | Node の execFile で git CLI 駆動 | `tokio::process::Command` で git 駆動（最短） |

## テスト

| 機能        | 用途              | JS / Effect 側 | Rust 推奨                         |
| ----------- | ----------------- | -------------- | --------------------------------- |
| 単体テスト  | 通常テスト        | Vitest         | 標準 `#[test]` / `#[tokio::test]` |
| 表示比較    | アサーション diff | Vitest         | `pretty_assertions`               |
| Snapshot    | 構造化出力比較    | （未使用）     | `insta`                           |
| HTTP モック | API モック        | （手書き）     | `mockito`                         |
| 一時 dir    | fs テスト fixture | （手書き）     | `tempfile`                        |

## 移植時の置換早見

JS/Effect の典型イディオムから Rust の対応イディオムへ:

| JS / Effect                                | Rust                                                                            |
| ------------------------------------------ | ------------------------------------------------------------------------------- |
| `Effect.gen(function*() { yield* x })`     | `async fn { x.await }`                                                          |
| `Effect.tryPromise({ try, catch })`        | `?` 演算子 + `thiserror` の `#[from]` (外部クレート由来は `.into_diagnostic()`) |
| `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`                                                     |
| `Option.isSome(x) ? x.value : default`     | `x.unwrap_or(default)`                                                          |
| `Schema.decodeUnknownEffect(T)(input)`     | `serde_json::from_value::<T>(input)?`                                           |
| `Data.TaggedError('Foo')<{...}>`           | `#[derive(thiserror::Error, miette::Diagnostic)] enum FooError { ... }`         |
| `process.env.X ?? flag`                    | `clap` の `#[arg(env = "X")]`                                                   |
| `Console.log(...)`                         | `println!("{...}", ...)`                                                        |
| `Effect.log(...)`                          | `tracing::info!(...)`                                                           |
