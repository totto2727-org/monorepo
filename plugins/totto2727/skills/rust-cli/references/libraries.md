# Rust CLI Libraries — JS/Effect ↔ Rust 完全対応表

非同期 Rust で CLI を実装する際の、機能カテゴリごとの推奨クレート。
JS / Effect 側の対応物を併記し、移植の見通しを立てやすくする。

## 表の見方

- **推奨**: 最初に検討すべきクレート（迷ったらこれ）
- **代替**: 要件に応じて検討する選択肢
- 非同期前提（tokio）。同期版が必要な場合は各クレートの blocking feature を参照

## コア（必須カテゴリ）

| 機能                        | 用途                           | JS / Effect 側                                            | Rust 推奨                                  | 代替 / 補足                              |
| --------------------------- | ------------------------------ | --------------------------------------------------------- | ------------------------------------------ | ---------------------------------------- |
| ランタイム                  | task / 並行 I/O                | `@effect/platform-node` `NodeRuntime` + `Effect.gen`      | `tokio` (`full` features)                  | `smol`, `async-std`（ニッチ）            |
| 引数解析                    | サブコマンド・フラグ・ヘルプ   | `effect/unstable/cli` (`Command`/`Flag`)                  | `clap` (`derive`)                          | `argh`, `bpaf`, `gumdrop`                |
| HTTP クライアント           | REST API（JSON/binary/header） | `effect/unstable/http` (`HttpClient` + `FetchHttpClient`) | `reqwest` (`json` + `rustls-tls`)          | `hyper`（低レベル）, `ureq`（同期）      |
| JSON                        | parse / stringify              | `JSON.*`                                                  | `serde` + `serde_json`                     | —                                        |
| スキーマ検証                | 不明値→型検査                  | `effect` `Schema.decodeUnknownEffect`                     | `serde` derive（型一致） + `garde`（値域） | `serde_valid`, `validator`, `jsonschema` |
| エラー型定義                | タグ付きエラー                 | `Data.TaggedError`                                        | `thiserror`                                | —                                        |
| エラー表示（CLI top-level） | 診断付きエラー出力             | —                                                         | `miette`                                   | `anyhow`（型ぼかし）, `color-eyre`       |
| Option / Result             | nullable / 失敗                | `Option`, `Effect`                                        | 標準 `Option<T>` / `Result<T, E>`          | —                                        |

## I/O・OS

| 機能           | 用途                             | JS / Effect 側                                | Rust 推奨                                 | 代替 / 補足                                        |
| -------------- | -------------------------------- | --------------------------------------------- | ----------------------------------------- | -------------------------------------------------- |
| 非同期ファイル | read/write/mkdir/rm              | `node:fs/promises`                            | `tokio::fs`                               | `async-fs`                                         |
| パス           | join / relative / dirname        | `node:path`                                   | 標準 `std::path`                          | `camino`（UTF-8 強制 + serde 連携）                |
| Symlink        | 作成 / 判定                      | `Fs.symlink`, `lstat().isSymbolicLink()`      | `tokio::fs::symlink` + `symlink_metadata` | Windows: `std::os::windows::fs::symlink_dir/file`  |
| 子プロセス     | `git` などの外部コマンド呼び出し | Node `child_process` の execFile（promisify） | `tokio::process::Command`                 | `tokio::task::spawn_blocking` で sync 処理を逃がす |
| 環境変数       | API トークン取得                 | `process.env`                                 | 標準 `std::env::var`                      | `dotenvy`（.env サポート）                         |
| 一時ファイル   | テスト fixture                   | （手書き）                                    | `tempfile`                                | RAII で自動削除                                    |
| ファイル排他   | lock-file 同時書き込み防止       | （手書き）                                    | `fd-lock`, `fs2`                          | —                                                  |

## 並行・並列

| 機能                 | 用途         | JS / Effect 側                             | Rust 推奨                               | 代替 / 補足                  |
| -------------------- | ------------ | ------------------------------------------ | --------------------------------------- | ---------------------------- |
| unbounded concurrent | 並列 I/O     | `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`             | `FuturesUnordered`（順不同） |
| 上限付き concurrent  | n 並列に制限 | `Effect.all({ concurrency: n })`           | `stream::iter(...).buffer_unordered(n)` | `JoinSet` + `Semaphore`      |
| panic 安全な spawn   | エラー分離   | —                                          | `tokio::task::JoinSet`                  | —                            |

## データ・フォーマット

| 機能                   | 用途                  | JS / Effect 側                      | Rust 推奨                | 代替 / 補足                            |
| ---------------------- | --------------------- | ----------------------------------- | ------------------------ | -------------------------------------- |
| YAML                   | frontmatter, config   | （現状未使用）                      | `serde_yml`              | `serde_yaml`（メンテ停止）             |
| TOML                   | config                | （現状未使用）                      | `toml`                   | `toml_edit`（編集向き）                |
| 設定（複数ソース統合） | env + file + CLI 統合 | `JSON.parse(readFile)` + 自前マージ | `figment`                | `config`                               |
| 日付・時刻             | TZ-aware datetime     | `Date`, `effect` DateTime           | `jiff`                   | `chrono`（legacy）, `time`（embedded） |
| グロブ                 | パターンマッチ        | （手書き）                          | `globset`                | `glob`                                 |
| ファイル走査           | gitignore 尊重再帰    | 手書き再帰 + `SKIP_DIRS`            | `ignore`（ripgrep 由来） | `walkdir`                              |
| 差分                   | dry-run プレビュー    | （手書き）                          | `similar`                | —                                      |

## 観測・出力

| 機能        | 用途         | JS / Effect 側 | Rust 推奨                        | 代替 / 補足                          |
| ----------- | ------------ | -------------- | -------------------------------- | ------------------------------------ |
| 構造化ログ  | 階層付きログ | `Effect.log`   | `tracing` + `tracing-subscriber` | `log` + `env_logger`（古典的）       |
| 単純 stdout | デバッグ出力 | `Console.log`  | 標準 `println!` / `eprintln!`    | —                                    |
| 色付け      | 装飾出力     | （現状なし）   | `owo-colors`                     | `console`, `nu-ansi-term`, `colored` |

## TUI / 対話 UI

[tui.md](./tui.md) も参照。

| レイヤ             | 用途                                | 推奨                     | 代替                                    |
| ------------------ | ----------------------------------- | ------------------------ | --------------------------------------- |
| L1: プロンプト     | select / input / confirm / password | `inquire`                | `dialoguer`（古参）, `cliclack`（美麗） |
| L1: 進捗・スピナー | プログレスバー / 待機表示           | `indicatif`              | `spinners`（フレーム集流用）            |
| L2: 宣言的 TUI     | React 風コンポーネント              | `iocraft`                | `dioxus-tui` / `rink`（実験的）         |
| L3: 命令的 / Elm   | フル画面ダッシュボード              | `tui-realm` on `ratatui` | `teatui`, `ratatui` 直叩き              |

## バージョン管理 / Git

| 機能     | 用途                            | JS / Effect 側                   | Rust 推奨                                     | 代替 / 補足                                |
| -------- | ------------------------------- | -------------------------------- | --------------------------------------------- | ------------------------------------------ |
| Git 操作 | clone / pull / fetch / checkout | Node の execFile で git CLI 駆動 | `tokio::process::Command` で git 駆動（最短） | `git2`（libgit2 バインディング、同期のみ） |

## テスト

| 機能        | 用途              | JS / Effect 側 | Rust 推奨                         | 代替 / 補足 |
| ----------- | ----------------- | -------------- | --------------------------------- | ----------- |
| 単体テスト  | 通常テスト        | Vitest         | 標準 `#[test]` / `#[tokio::test]` | —           |
| 表示比較    | アサーション diff | Vitest         | `pretty_assertions`               | —           |
| Snapshot    | 構造化出力比較    | （未使用）     | `insta`                           | —           |
| HTTP モック | API モック        | （手書き）     | `mockito`                         | `wiremock`  |
| 一時 dir    | fs テスト fixture | （手書き）     | `tempfile`                        | —           |

## 移植時の置換早見

JS/Effect の典型イディオムから Rust の対応イディオムへ:

| JS / Effect                                | Rust                                                |
| ------------------------------------------ | --------------------------------------------------- |
| `Effect.gen(function*() { yield* x })`     | `async fn { x.await }`                              |
| `Effect.tryPromise({ try, catch })`        | `?` 演算子 + `thiserror` の `#[from]`               |
| `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`                         |
| `Option.isSome(x) ? x.value : default`     | `x.unwrap_or(default)`                              |
| `Schema.decodeUnknownEffect(T)(input)`     | `serde_json::from_value::<T>(input)?`               |
| `Data.TaggedError('Foo')<{...}>`           | `#[derive(thiserror::Error)] enum FooError { ... }` |
| `process.env.X ?? flag`                    | `clap` の `#[arg(env = "X")]`                       |
| `Console.log(...)`                         | `println!("{...}", ...)`                            |
| `Effect.log(...)`                          | `tracing::info!(...)`                               |
