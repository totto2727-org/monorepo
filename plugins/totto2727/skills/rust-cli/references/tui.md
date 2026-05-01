# Rust CLI — TUI / 対話 UI 詳細

ローディング・セレクト・インプットの 3 要件を中心に、レイヤ別に詳細を示す。

## レイヤ早見

| レイヤ | 用途 | 推奨 | 特徴 |
| --- | --- | --- | --- |
| L1 | 単発プロンプト + スピナー | `inquire` + `indicatif` | 既存 CLI に最小コストで追加可能 |
| L2 | 宣言的フォーム / React-like | `iocraft` | Ink 直系、props/state、tokio 互換 |
| L3 | フル画面 Elm Architecture | `tui-realm` on `ratatui` | Component + Message/Update |

「どれを選ぶか」の判断基準は **画面遷移と状態管理の複雑性**。
スピナー＋プロンプトを入れたいだけなら L1 で止めるのが最短。

## L1: `inquire` + `indicatif`

JS で言う `inquirer` / `prompts` + `ora` 相当。

### `inquire`（プロンプト）

提供されるウィジェット: `Select`, `MultiSelect`, `Text`, `Password`, `Confirm`, `Editor`, `DateSelect`, `CustomType`, autocomplete 付き Select。
バリデーション・ページング・タブ補完が組み込み。`dialoguer` より UI 体験が一段良い。

### `indicatif`（進捗 / スピナー）

- `ProgressBar::new_spinner()` でスピナー、`ProgressBar::new(n)` で bounded プログレスバー
- `MultiProgress` で複数バー併走
- `set_style(ProgressStyle::with_template(...))` でテンプレート文字列指定

### 並用パターン

prompt → 進捗バー表示 → 完了。スピナー連発系の単発スクリプトはこのレイヤで完結する。

## L2: `iocraft`（推奨・宣言的）

Ink (Node) 直系の React 風 TUI。`#[component]` + `element!` マクロで JSX 風記法。
**ランタイム非依存**（依存は `crossterm` + `futures` + `taffy`）で `#[tokio::main]` と素直に組み合わせ可能。

### 主要 API

| API | 役割 |
| --- | --- |
| `#[component] fn Foo(...)` | 関数コンポーネント定義（React 風） |
| `element! { ... }` | RSX 風 UI 記述マクロ |
| `View`, `Text`, `TextInput` | ビルトインコンポーネント（少数） |
| `hooks.use_state(\|\| ...)` | ローカル状態 |
| `hooks.use_future(async move { ... })` | 非同期駆動（タイマー / API 呼び出し） |
| `hooks.use_context_mut::<SystemContext>()` | exit 等のシステム操作 |
| `element!(App).render_loop().await` | 描画ループ（Future） |
| `element!(App).print()` | 単発出力（インライン） |

### スピナーは自作（10 行）

ビルトイン Spinner は無いが、`use_state` + `use_future` で簡単に書ける。
実装例は [../templates/spinner.rs](../templates/spinner.rs) を参照。

公式 example の `progress_bar.rs` が同パターン:
[github.com/ccbrown/iocraft/blob/main/examples/progress_bar.rs](https://github.com/ccbrown/iocraft/blob/main/examples/progress_bar.rs)

### tokio 互換性の根拠

- iocraft の `Cargo.toml` には `tokio` / `smol` の **runtime 依存が無い**
- examples が smol を使っているのは「examples の都合」
- `render_loop()` は `impl Future`、`use_future` は任意の `Future` を受ける
- `#[tokio::main]` 配下で `.await` する形で問題なく動作する
- `use_future` 内のタイマーは `tokio::time::sleep` でよい

### できること / 注意点

| 項目 | 対応 |
| --- | --- |
| 単一スピナー | ◯ 10 行で実装 |
| プログレスバー | ◯ 公式 example あり |
| 複数スピナー並走 | ◯ 各 `use_future` が独立 |
| 完了で色変更 / アイコン切替 | ◯ props / state で制御 |
| tokio + reqwest と併用 | ◯ ランタイム非依存 |
| インライン出力 | ◯ `.print()` |
| プリセット（フレーム集・テンプレ文字列） | ✗ 自作。`spinners` クレートの定数借用が楽 |
| ETA / 速度計測 | ✗ 必要なら自前 or `indicatif` 並用 |
| ターミナル幅追従 / リサイズ | ◯ crossterm + taffy 処理 |

## L3: `tui-realm` on `ratatui`

ratatui は immediate-mode の低レベル描画ライブラリ。これに React + Elm 折衷の状態管理を被せたのが tui-realm（"Realm" = **R**eact + **E**lm）。

### 構成要素

- **Component**: 再利用可能な UI 部品（props / state を持つ）
- **Application**: Component を束ねる
- **Update / Message**: Elm の Update 関数相当でメッセージ駆動
- **Event**: 入力イベント

ダッシュボード・ウィザード等の **複数画面・大規模状態** が必要な場合に検討する。

### 代替

- `teatui` — BubbleTea 直系、純 Elm（実験段階）
- `ratatui` 直叩き + 自作 Elm ループ — 公式に "The Elm Architecture" のチュートリアルあり

## 選択指針（フローチャート的）

1. 入力が `y/n` / `select` / `text` / 進捗表示だけ？ → **L1（inquire + indicatif）**
2. フォーム複雑 / 動的 UI / Ink 知識を流用したい？ → **L2（iocraft）**
3. フル画面ダッシュボード / 多画面遷移？ → **L3（tui-realm）**

迷ったら L1 から始めて、要件が増えたら L2 → L3 へ昇格。
**iocraft は L1 の機能も含むため、最初から iocraft 一本に統一する設計も合理的**。

## 関連リソース

- [iocraft GitHub](https://github.com/ccbrown/iocraft)
- [iocraft examples](https://github.com/ccbrown/iocraft/tree/main/examples)
- [inquire](https://github.com/mikaelmello/inquire)
- [indicatif](https://github.com/console-rs/indicatif)
- [tui-realm](https://github.com/veeso/tui-realm)
- [ratatui — The Elm Architecture](https://ratatui.rs/concepts/application-patterns/the-elm-architecture/)
