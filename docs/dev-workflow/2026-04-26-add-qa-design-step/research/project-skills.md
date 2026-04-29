# Research Note: project-skills

- **Identifier:** 2026-04-26-add-qa-design-step
- **Topic:** project-skills
- **Researcher:** Main (intent-analyst → researcher 兼任、Explore Agent 結果を統合)
- **Created at:** 2026-04-26T13:40:00Z
- **Scope:** monorepo 内のテスト関連プロジェクト固有スキルを棚卸しし、qa-analyst が Step 4 起動時にデフォルトで参照すべきスキルセットを決定する

## 調査対象

dev-workflow の汎用ワークフローを引き継ぎつつ、テスト基盤 (vitest / moonbit test / etc.) の選定はプロジェクト固有スキルに委譲する設計。qa-analyst 起動時にどのスキルを Specialist 入力として渡せばよいかを確定する。

## 発見事項

### monorepo のプラグイン構成

- 4 プラグイン: `totto2727`, `dev-workflow`, `moonbit`, `components-build`
- `plugins/<name>/.claude-plugin/plugin.json` で各プラグイン定義
- 計 28 スキルが `plugins/<plugin>/skills/<name>/SKILL.md` 形式で存在

### テスト直接言及スキル (description ベース)

| #   | スキル名                                      | パス (plugins/<plugin>/skills/...)          | 短い説明                                                      |
| --- | --------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| 1   | `specialist-validator`                        | `dev-workflow/skills/specialist-validator/` | Step 8 成功基準実測・検証レポート (qa-analyst と隣接領域)     |
| 2   | `shared-artifacts` (`validation-report` 部分) | `dev-workflow/skills/shared-artifacts/`     | テスト実行結果・メトリクス・証拠保存フォーマット              |
| 3   | `specialist-reviewer` (`test-quality` 観点)   | `dev-workflow/skills/specialist-reviewer/`  | テスト品質をレビュー観点として扱う                            |
| 4   | `moonbit-bestpractice` (Section 6 Testing)    | `moonbit/skills/moonbit-bestpractice/`      | MoonBit テスト規約 (`test "..."{ }` 形式・debug_inspect 用法) |
| 5   | `specialist-common`                           | `dev-workflow/skills/specialist-common/`    | Specialist 共通基盤 (qa-analyst もこれを継承)                 |
| 6   | `moonbit-docs`                                | `moonbit/skills/moonbit-docs/`              | MoonBit 言語リファレンス (テスト API は副次)                  |

### 既存 ADR

- `doc/adr/2026-04-09-c-plugin-test-strategy.md` (`confirmed: false`)
  - c-plugin の service-level integration test 戦略
  - vitest (`vp test`) ベース、temp ディレクトリベースのテスト基盤
  - Mock 戦略 (Git 操作の `vi.mock`) の precedent

### プロジェクト共通のテストコマンド (CLAUDE.md / Taskfile.yml より)

- `vp test` — Vitest 経由の workspace 横断テスト実行
- `vp test run <file>` — 特定ファイル
- `vp test related <source>` — ソースに関連するテスト
- `moon test` — MoonBit パッケージのテスト
- いずれも具体ツール名は qa-design.md には書かない (Intent Spec 非スコープ)

## 引用元

- `plugins/totto2727/.claude-plugin/plugin.json`
- `plugins/dev-workflow/.claude-plugin/plugin.json`
- `plugins/moonbit/.claude-plugin/plugin.json`
- `plugins/components-build/.claude-plugin/plugin.json`
- 各 skills/<name>/SKILL.md の frontmatter description
- `doc/adr/2026-04-09-c-plugin-test-strategy.md`
- `CLAUDE.md` (リポジトリルート、`vp test` 言及)

## 設計への含意

### qa-analyst デフォルト参照すべきスキル (起動時に Main が渡す)

**必須セット (3 件):**

1. `specialist-common` — Specialist としてのライフサイクル / 入出力契約 / 失敗時プロトコル / スコープ規律 / プロジェクト固有ルール優先順位 (全 specialist が継承)
2. `specialist-validator` — Step 9 で同じ qa-design を実測する側の手法と契約。qa-analyst の出力フォーマットを validator が解釈できる形に整合させる必要
3. `shared-artifacts` (特に `references/qa-design.md`, `references/qa-flow.md` を新設後) — qa-analyst の出力フォーマットの真のソース

**追加推奨 (プロジェクト言語に応じて):**

4. プロジェクト言語のテスト規約スキル (TS なら `vite-plus`, MoonBit なら `moonbit-bestpractice`, Go なら別途)
5. プロジェクト固有のテスト戦略 ADR (例: `2026-04-09-c-plugin-test-strategy.md` のような既存 precedent)

### qa-analyst 起動プロトコル

Main は qa-analyst 起動時に以下を**入力に含める**こと (specialist-common の入力契約に従う):

- intent-spec.md (成功基準を深掘りする元)
- design.md (アーキテクチャから自動 vs 手動を判断する材料)
- shared-artifacts の qa-design.md / qa-flow.md の reference + template パス
- specialist-validator スキルへのパス参照 (出力形式の整合性確認用)
- プロジェクトの言語/フレームワーク固有テストスキル (該当言語に応じて、Main が選定)
- 過去サイクル / 既存 ADR のうち、テスト戦略に関連するもの (例: c-plugin-test-strategy)

不足があれば qa-analyst から Main に問い合わせる (specialist-common の入力契約)。

## 残存する不明点

- **言語自動検出**: qa-analyst が「プロジェクト言語が TS なのか MoonBit なのか」を Main から渡されるべきか、Main が design.md を読んで判断すべきか → Step 3 Design で設計判断
- **ADR の自動参照**: `doc/adr/` 配下の test-strategy 系を qa-analyst が自動で読み込む仕組みがあると便利だが、現状の Specialist 入力契約では「Main が明示的に渡す」運用 → 当面はこの運用を維持
