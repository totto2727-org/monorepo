# Research Note: Claude Code Plugin Structure

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Topic:** plugin-structure
- **Researcher:** （plugin-dev:plugin-structure スキルを参照）
- **Created at:** 2026-04-24T13:22:00Z
- **Scope:** Claude Code プラグインの標準ディレクトリ構造・マニフェスト仕様・自動探索挙動

## 調査対象

ai-dlc プラグインを `plugins/ai-dlc/` 配下に配置するための**準拠すべき構造**と、既存プラグインとの整合性。

## 発見事項

**必須構造:**

- `.claude-plugin/plugin.json` にマニフェスト（`name` 必須、kebab-case）
- コンポーネントは**プラグインルート直下**（`.claude-plugin/` 配下ではない）
- `skills/<name>/SKILL.md`（大文字厳密）
- `agents/<name>.md`（frontmatter に `description` 必須）
- 命名は kebab-case

**自動探索:**

- `commands/` / `agents/` / `skills/` / `hooks/hooks.json` / `.mcp.json` は自動探索される
- `plugin.json` の `commands` / `agents` などで追加パスを指定可能（デフォルトを置き換えるのではなく補完）

**既存リポジトリ内プラグイン例** (`plugins/totto2727/`, `plugins/moonbit/`, `plugins/components-build/`):

- 各 `plugin.json` は `name` / `description` / `version` / `author` を含む
- `plugins/totto2727/skills/adr/SKILL.md` は `---` delimited YAML frontmatter + Markdown 本文
- スキルディレクトリには `SKILL.md` と、必要に応じ `templates/`, `references/` のサブディレクトリを同居させる例あり（例: `plugins/totto2727/skills/skill-reviewer/`）

## 引用元

- `plugin-dev:plugin-structure` スキル（ドキュメント読み込み）
- `plugins/totto2727/.claude-plugin/plugin.json` — マニフェスト実例
- `plugins/totto2727/skills/skill-reviewer/` — references / templates を持つスキル構造の実例
- `plugins/totto2727/skills/adr/SKILL.md` — frontmatter 記法の実例

## 設計への含意

- `plugins/ai-dlc/.claude-plugin/plugin.json` にマニフェストを配置
- スキルはルート直下 `plugins/ai-dlc/skills/<name>/SKILL.md` の形式
- エージェントは `plugins/ai-dlc/agents/<name>.md`
- スキル内に `templates/` と `references/` を持つパターンは既存スキル（`skill-reviewer`）でも採用されており、shared-artifacts でも同パターンが使える
- 命名は kebab-case で `main-*` / `specialist-*` / `shared-*` のプレフィックス運用が可能
- マニフェストの `name` は `ai-dlc`（単一プラグインとして登録）

## 残存する不明点

- スキル名に prefix を付ける慣習がプラグイン全体で定着しているか（本サイクルで新規導入）
- shared-artifacts の references 内容を他スキル側からどう参照するかのベストプラクティス（相対パス vs `${CLAUDE_PLUGIN_ROOT}`）→ 本サイクルでは相対パス表記で統一
