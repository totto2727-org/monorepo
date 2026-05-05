# Research Note: Claude Code plugin discovery mechanism

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Topic:** plugin-discovery-mechanism
- **Researcher:** researcher (plugin discovery hypothesis verification perspective)
- **Created at:** 2026-05-04
- **Scope:** 先行 Note `skills-lock-registry.md` が末尾に残した仮説 (本リポジトリ `.claude-plugin/marketplace.json` を Claude Code 本体が直接読んで plugin/skill を発見する) を実証ベースで検証し、Intent Spec Open Question #1 (dotfiles 側更新の要否) と #2 (新プラグイン登録形式) の最終回答を確定する。

## Subject of investigation

本 Note は以下に限定する:

- 本リポジトリ `dev-workflow` プラグイン (本リポジトリ `.claude-plugin/marketplace.json` には登録、dotfiles `totto2727-dotfiles/agents` 側 marketplace には未登録、本リポジトリ `.agents/skills-lock.json` には未登録) が**現セッションで Claude Code に認識されている**事実から、Claude Code 本体の plugin discovery 経路を特定する
- 公式仕様 (`code.claude.com/docs/en/plugin-marketplaces`, `plugins-reference`, `discover-plugins`, `settings`) の該当条文の確認
- ローカル設定ファイル (`~/.claude/settings.json`, project `.claude/settings.json`, `~/.claude/plugins/known_marketplaces.json`, `~/.claude/plugins/installed_plugins.json`) の現状確認
- `c-plugin sync` (本リポジトリ `js/app/c-plugin/`) と Claude Code 本体 plugin loader の関係性の判別

スコープ外: `coding/SKILL.md` 構造設計、`test/SKILL.md` の TS セクション扱い、CLAUDE.md への追記要否 (他観点 / 後続ステップ)。

## Findings

### 1. dev-workflow プラグインは本リポジトリ marketplace 経由で認識されている (実証)

- **本リポジトリ `.claude-plugin/marketplace.json:23-25`**: `dev-workflow` プラグインが `source: "./plugins/dev-workflow"` で登録されている (4 件中 4 番目、最後に追加)
- **dotfiles 側 marketplace (`totto2727-dotfiles/agents/.claude-plugin/marketplace.json`)**: 先行 Note 確認済 = `dev-workflow` 不在 (`totto2727`, `moonbit`, `components-build` の 3 件のみ)
- **本リポジトリ `.agents/skills-lock.json:1-23`**: `enabledSkills` に `dev-workflow` 由来のスキル名は**一切登録されていない** (`moonbit-bestpractice`, `moonbit-docs`, `components-build-docs` のみ)
- **`~/.claude/plugins/installed_plugins.json:204-214`**: `dev-workflow@totto2727` エントリは存在し `scope: "project"`, `projectPath: "/Users/totto2727/proj/monorepo"`, `installPath: "/Users/totto2727/.claude/plugins/cache/totto2727/dev-workflow/0.1.0"`, `gitCommitSha: "a0e22c21cfeea523212f5e9fc0bda985fd005a68"` が記録
- **しかし `~/.claude/plugins/cache/totto2727/`**: `components-build`, `moonbit`, `totto2727` の 3 ディレクトリのみ実在し、**`dev-workflow` cache ディレクトリは物理的に存在しない** (`ls` で空)
- **現セッションの available skills 一覧**: `dev-workflow:dev-workflow`, `dev-workflow:specialist-researcher`, `dev-workflow:share-artifacts`, `dev-workflow:share-pr-manager`, `dev-workflow:share-ci-monitoring`, `dev-workflow:share-adr` 等、**dev-workflow 配下の全スキルがシステムプロンプトに列挙**されている (本セッションのプロンプト先頭 skill 一覧で確認)

→ **実証された結論**: `dev-workflow` は (a) dotfiles registry にも (b) `.agents/skills-lock.json` にも登録されておらず、(c) `~/.claude/plugins/cache/` にも実体がない。にもかかわらず Claude Code 本体に認識されている。**これが成立する経路は「本リポジトリ `.claude-plugin/marketplace.json` を Claude Code 本体が `extraKnownMarketplaces` 経由で直接解決し、plugin source `./plugins/dev-workflow` を in-place で読み込んでいる」以外にない**。

### 2. project `.claude/settings.json` が plugin 認識のトリガー

- **`.claude/settings.json:3-16`** (project scope, git commit 済) に以下が記述されている:
  ```json
  "enabledPlugins": {
    "dev-workflow@totto2727": true,
    "components-build@totto2727": true,
    "moonbit@totto2727": true,
    "totto2727@totto2727": true
  },
  "extraKnownMarketplaces": {
    "totto2727": {
      "source": {
        "source": "directory",
        "path": "./"
      }
    }
  }
  ```
- `extraKnownMarketplaces.totto2727.source.source: "directory"` + `path: "./"` は、本リポジトリのルート (`.claude-plugin/marketplace.json` を含むディレクトリ) を marketplace の在処として直接指している
- `enabledPlugins` の 4 件はすべて本リポジトリ `marketplace.json` の `plugins[]` (4 件) と name で完全一致
- **`~/.claude/plugins/known_marketplaces.json:11-15`**: `totto2727` marketplace が `source: { source: "directory", path: "/Users/totto2727/proj/monorepo" }`, `installLocation: "/Users/totto2727/proj/monorepo"` で登録済 (= ローカルパスを直接指し、`marketplaces/<name>/` 配下にコピーしない)

→ project settings の `extraKnownMarketplaces` (directory source) が起動時に解決され、`marketplace.json` がその場で読まれている。

### 3. 公式仕様: directory source は worktree でも main checkout に解決される

公式 `code.claude.com/docs/en/plugin-marketplaces` (Note ブロック) より引用:

> If you use a local `directory` or `file` source with a relative path, the path resolves against your repository's main checkout. **When you run Claude Code from a git worktree, the path still points at the main checkout, so all worktrees share the same marketplace location.** Marketplace state is stored once per user in `~/.claude/plugins/known_marketplaces.json`, not per project.

- 検証: 現セッションは worktree (`/Users/totto2727/proj/monorepo/.claude/worktrees/humming-dreaming-pancake`) で起動しているにもかかわらず、`known_marketplaces.json` の `totto2727.installLocation` は **main checkout のパス `/Users/totto2727/proj/monorepo`** を指している → 公式仕様通り
- `extraKnownMarketplaces` のうち directory source は **path: "./" → main checkout** に解決される (`~/.claude/plugins/known_marketplaces.json:14`)
- worktree から `.claude-plugin/marketplace.json` や `plugins/dev-workflow/` を直接編集しても、**Claude Code 本体は main checkout 側を参照する** = worktree での先行的 plugin 追加は次回 main checkout を更新するまで反映されない可能性あり (Implications #4 参照)

### 4. 公式仕様: `extraKnownMarketplaces` + `enabledPlugins` で team 共有

公式 `code.claude.com/docs/en/discover-plugins` (Configure team marketplaces) より引用:

> Team admins can set up automatic marketplace installation for projects by adding marketplace configuration to `.claude/settings.json`. **When team members trust the repository folder, Claude Code prompts them to install these marketplaces and plugins.**

公式 `code.claude.com/docs/en/plugin-marketplaces` (Require marketplaces for your team) より引用:

> You can also specify which plugins should be enabled by default:
>
> ```json
> {
>   "enabledPlugins": {
>     "code-formatter@company-tools": true,
>     "deployment-tools@company-tools": true
>   }
> }
> ```

- 動作: 「project を trust するとプロンプトが出て install される」 → 一度受諾後は `~/.claude/plugins/installed_plugins.json` にエントリが記録され、以降のセッションでは自動有効化される
- 本リポジトリ `installed_plugins.json:204-214` に `dev-workflow@totto2727` が `scope: "project"` で記録されているのは、**過去にユーザーが trust prompt で承諾した結果**と推定 (`installedAt: "2026-04-26T07:24:53.752Z"`)
- 一方で `~/.claude/plugins/cache/totto2727/dev-workflow/` は不在 → directory source の場合は **cache を作らず、source path を在処そのものとして都度参照する** (cache を作るのは github / npm 等の remote source のみ)

### 5. 公式仕様: directory source の plugin は cache を経由しない可能性が高い

公式 `code.claude.com/docs/en/plugin-marketplaces` (line 113 相当) より引用:

> **How plugins are installed**: When users install a plugin, Claude Code copies the plugin directory to a cache location.

- ただしこれは一般則。directory source + project scope の組み合わせでは **cache に dev-workflow が物理的に存在しないのに skill が available** という事実 (Findings #1) から、**directory source は cache をスキップして source path を直接読む** と推定するのが整合的
- `installed_plugins.json` の `installPath` は名目上の「論理的インストール場所」のみで、directory source では実体パス (`extraKnownMarketplaces.<name>.source.path` + plugin の `source` 相対パス) が実体として使われている

### 6. `c-plugin sync` は Claude Code 本体 plugin loader と完全に独立

- スキーマ: `js/app/c-plugin/src/schema/lock-file.ts:13` `marketplaceKind: Schema.Literals(['claude', 'cursor', 'codex'])` → **Claude Code 専用ではなく、Cursor / Codex も対象とするマルチプラットフォーム skill 同期ツール**
- 出力先: `js/app/c-plugin/src/service/symlink.ts:33-47` `getAllDirs(agentsDir, skillDirs)` → **`.agents/skills/` (本リポジトリ) と `~/.agents/skills/` (グローバル) に symlink を張る**
- 実体検証: 本リポジトリ `.agents/skills/` (worktree) の `ls -la`:
  - `components-build-docs -> ../.cache/totto2727-dotfiles/agents/plugins/components-build/skills/components-build-docs` (symlink)
  - `moonbit-bestpractice -> ../.cache/totto2727-dotfiles/agents/plugins/moonbit/skills/moonbit-bestpractice` (symlink)
  - `moonbit-docs -> ../.cache/totto2727-dotfiles/agents/plugins/moonbit/skills/moonbit-docs` (symlink)
  - `effect-layer/`, `effect-runtime/`, `effect-hono/`, `totto2727-fp/` は **実ディレクトリ (= 直置き skill, lock 経由ではなく開発者が直接配置)**
- これらは **`~/.agents/skills/` を skill 探索パスとして利用する別の AI ツール (Cursor, Codex) や、Claude Code 以外の用途向けのスキル配布機構**
- 公式 Claude Code は `.agents/skills/` を skill source として参照する仕組みを持たない (公式ドキュメントに `.agents/` への言及なし)

→ `c-plugin sync` の symlink は **Claude Code 本体の plugin loader には影響しない**。Claude Code 本体は `~/.claude/plugins/` 系統 (extraKnownMarketplaces / installed_plugins.json) のみ参照する。

### 7. `dev-workflow` が `c-plugin` 系統に登録されていない理由

- 先行 Note `skills-lock-registry.md` Findings #3 で確認済: dotfiles 側 marketplace に `dev-workflow` 不在 → `c-plugin sync` は dotfiles repo を clone して marketplace.json を読むため、`dev-workflow` を sync 対象として認識できない
- にもかかわらず `dev-workflow` は Claude Code 本体に認識 → Claude Code 本体の plugin loader (`.claude/settings.json` の `extraKnownMarketplaces` + `enabledPlugins` 経由) と `c-plugin sync` (lock file → dotfiles → `.agents/skills/` symlink) は **完全に独立した 2 つのシステム**

### 8. 本リポジトリ marketplace 名と dotfiles marketplace 名の重複

- `~/.claude/plugins/known_marketplaces.json:1-15` には 2 つの `totto2727` 関連エントリがある:
  - `claude-plugins-official` (Anthropic 公式)
  - `totto2727` (`source: directory, path: /Users/totto2727/proj/monorepo`) ← 本リポジトリ
- 一方 `~/.claude/settings.json:62-69` には:
  ```json
  "extraKnownMarketplaces": {
    "totto2727": {
      "source": {
        "source": "github",
        "repo": "totto2727-dotfiles/agents"
      }
    }
  }
  ```
  → user scope では `totto2727` marketplace が **github source (dotfiles)** に向いている
- project scope (`.claude/settings.json:9-16`) では `totto2727` が **directory source (本リポジトリ)** に向いている
- → **同名 marketplace `totto2727` の解決は scope precedence に従い、project が user を上書き** している。本リポジトリで `claude` を起動した場合、`totto2727` = 本リポジトリ marketplace で解決される

## Sources

- `.claude/settings.json:1-23` (project scope settings、`extraKnownMarketplaces.totto2727` directory source / `enabledPlugins.dev-workflow@totto2727: true`)
- `.claude-plugin/marketplace.json:1-27` (本リポジトリ marketplace、`dev-workflow` 4 番目に登録)
- `.agents/skills-lock.json:1-23` (`dev-workflow` 系スキル**未登録**)
- `~/.claude/settings.json:46-69` (user scope、`enabledPlugins` に `claude-plugins-official` 系 + `totto2727@totto2727`、`extraKnownMarketplaces.totto2727` は github source)
- `~/.claude/plugins/known_marketplaces.json:1-15` (`totto2727` marketplace の installLocation = `/Users/totto2727/proj/monorepo`)
- `~/.claude/plugins/installed_plugins.json:204-214` (`dev-workflow@totto2727` project scope, gitCommitSha `a0e22c21...`、cache 不在)
- `~/.claude/plugins/cache/totto2727/` の `ls` 結果 (`components-build`, `moonbit`, `totto2727` のみ、`dev-workflow` 不在)
- `.agents/skills/` の `ls -la` 結果 (effect-_ / totto2727-fp は実ディレクトリ、moonbit-_ / components-build-docs は dotfiles cache への symlink)
- `js/app/c-plugin/src/schema/lock-file.ts:11-19` (`marketplaceKind: ['claude', 'cursor', 'codex']`)
- `js/app/c-plugin/src/service/symlink.ts:33-47` (symlink 出力先 = `.agents/skills/`)
- 公式仕様 `https://code.claude.com/docs/en/plugin-marketplaces` (directory source / worktree / extraKnownMarketplaces / 113 行目 cache copy)
- 公式仕様 `https://code.claude.com/docs/en/discover-plugins` (Configure team marketplaces セクション、trust prompt)
- 公式仕様 `https://code.claude.com/docs/en/plugins-reference` (skills auto-discovery)
- 公式仕様 `https://code.claude.com/docs/en/settings` (extraKnownMarketplaces / enabledPlugins スキーマ)
- 先行 Note `docs/workflow/2026-05-04-totto2727-coding-plugin/research/skills-lock-registry.md` (`.agents/skills-lock.json` 観点)
- ADR `docs/adr/2026-04-06-c-plugin-cli-tool.md:1-211` (c-plugin の役割定義)
- 現セッションのシステムプロンプト先頭 skill 一覧 (dev-workflow:\* が available として列挙されている事実)

## Implications for design

### 結論: Intent Spec Open Question #1 (dotfiles 側更新の要否) → **不要**

**先行 Note `skills-lock-registry.md` Implications #1-#7 の判定 (= 必須・Blocker) を本 Note は実証データに基づき上書きする**。先行 Note は `.agents/skills-lock.json` (= `c-plugin sync` 経路) のみを検討対象としていたため、Claude Code 本体の plugin discovery 経路 (`.claude-plugin/marketplace.json` 直読み) の存在を検証できておらず、Blocker と結論付けたのは **対象範囲の取り違え**。

#### 採用すべき方式: **方式 E — 本リポジトリ `.claude-plugin/marketplace.json` 更新のみ (新方式、本 Note で確立)**

| 方式                                       | 内容                                                                                                                                                                                                                                                                                                        | 評価         | 根拠                                                                                                                                          |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **E (推奨)**                               | 本リポジトリ `.claude-plugin/marketplace.json` の `plugins[]` に `{"name": "totto2727-coding", "source": "./plugins/totto2727-coding"}` を追加し、本リポジトリ `plugins/totto2727-coding/` に実体を配置。project `.claude/settings.json` の `enabledPlugins` に `"totto2727-coding@totto2727": true` を追加 | **○ (推奨)** | dev-workflow と同一の運用パターン (Findings #1-#5)。dotfiles 側更新不要。Intent Spec Out of scope 維持可能                                    |
| A (先行 Note 推奨)                         | dotfiles `totto2727-dotfiles/agents` に `totto2727-coding` 追加                                                                                                                                                                                                                                             | × (不要)     | Claude Code 本体は dotfiles を経由せず directory source で本リポジトリを読むため、dotfiles 追加は機能上不要 (dev-workflow と同様の前例で実証) |
| B (skillDirs)                              | 先行 Note 評価通り                                                                                                                                                                                                                                                                                          | ×            | `c-plugin` の symlink 出力先機能、Claude Code 本体には無関係                                                                                  |
| C (本リポジトリ自身を repositories[] 追加) | 先行 Note 評価通り                                                                                                                                                                                                                                                                                          | ×            | GitHub clone 強制、ローカル変更が反映されない                                                                                                 |
| D-1/D-2                                    | 先行 Note 評価通り                                                                                                                                                                                                                                                                                          | ×            | sync 経路で完結しない / c-plugin 機能追加が必要                                                                                               |

#### 必要な作業 (Step 5 Task Decomposition への申し送り)

1. **本リポジトリ `.claude-plugin/marketplace.json` の `plugins[]` に新エントリ追加** (5 番目):
   ```json
   {
     "name": "totto2727-coding",
     "source": "./plugins/totto2727-coding"
   }
   ```
2. **本リポジトリ `plugins/totto2727-coding/.claude-plugin/plugin.json` を作成** (既存 `plugins/dev-workflow/.claude-plugin/plugin.json:1-11` を雛形として、`name: "totto2727-coding"`, `description`, `version: "0.1.0"`, `author` を記述)
3. **project `.claude/settings.json` の `enabledPlugins` に追加** (`.claude/settings.json:3-8` の 4 行目以降):
   ```json
   "totto2727-coding@totto2727": true
   ```
4. **`plugins/totto2727-coding/skills/{coding,test,moonbit-docs,components-build-docs}/SKILL.md` 配下の実体配置** (Intent Spec Scope.1-3 のとおり)
5. **`.agents/skills-lock.json` 更新は別観点 (先行 Note 担当)**:
   - 旧スキル名 (`moonbit-bestpractice`, `moonbit-docs`, `components-build-docs`) のエントリ整理
   - **`totto2727-coding` を `.agents/skills-lock.json` に追加するかは要検討** (Implications #2 参照)

### Implications #2: `.agents/skills-lock.json` への `totto2727-coding` 登録は「不要」だが要ユーザー確認

- 先行 Note Implications #4 が指摘した「`enabledSkills` 値整合性」は **Claude Code 本体の plugin loader には無関係** (Claude Code は `.agents/skills-lock.json` を読まない)
- `.agents/skills-lock.json` を更新する**唯一の動機は `c-plugin sync` 経由で `~/.agents/skills/` (グローバル) や本リポジトリ `.agents/skills/` に symlink を張ること** (= Cursor / Codex 等の他 AI ツール用の skill 配布)
- 現状 `dev-workflow` プラグインも lock に未登録のまま運用されている (Findings #7) ことから、**totto2727-coding も lock 未登録のまま運用するのが既存方針との整合性が高い**
- ただし Intent Spec Scope.4 (`intent-spec.md:116-122`) は `.agents/skills-lock.json` 更新を Scope に含めている → この Scope 自体が技術的に不要だった可能性がある
- **本観点の推奨**: Step 3 (Architect) で Main 経由でユーザーに「`.agents/skills-lock.json` は Claude Code 本体には影響しないため Scope.4 は撤回してよいか」を確認。撤回された場合は Intent Spec Open Question #2 と Scope.4 が同時に消える
- もし「Cursor/Codex でも totto2727-coding を使えるようにしたい」要件が判明した場合は、初めて方式 A (dotfiles 側追加) が必要になる (本リポジトリ marketplace は `c-plugin` 側 schema が `sourceType: 'github'` 固定のため `repositories[]` には入れられず、dotfiles 経由でしか sync できない)

### Implications #3: Intent Spec SC-5 (skills-lock.json 検証) の解釈変更が必要

Intent Spec `## Success criteria` 第 5 項目 (`intent-spec.md:176-178`):

> 5. **`.agents/skills-lock.json` 更新の検証** — JSON をパースして以下を確認:
>    - 旧スキル名 (...) を含む `enabledSkills` エントリが旧プラグイン文脈で存在しない
>    - `totto2727-coding` プラグインがエントリとして登録され、`enabledSkills` に新スキル名が含まれる

- 上記 Implications #2 に基づき、Architect は SC-5 を以下のいずれかに改訂する判断材料を Main に提供する:
  - **(i) SC-5 を撤回**: `.agents/skills-lock.json` は本サイクルでは更新しない (Cursor/Codex 用途は別サイクル)
  - **(ii) SC-5 を「旧スキル名削除のみ」に縮小**: `moonbit-bestpractice` / `moonbit-docs` / `components-build-docs` の旧プラグイン文脈エントリを削除する (これは現在の lock を整理する作業として独立に意味あり)
  - **(iii) SC-5 を維持**: dotfiles 側に `totto2727-coding` を追加する付随サイクルを別途立てる (ユーザーが `c-plugin sync` で他 AI ツールへの配布を希望する場合)
- ユーザー判断が必要 → Architect (Step 3) が Main 経由で確認

### Implications #4: worktree からの先行配置に注意

- Findings #3 のとおり、Claude Code は worktree からでも main checkout の `marketplace.json` / `plugins/` を読む
- 本サイクルが worktree (`/Users/totto2727/proj/monorepo/.claude/worktrees/humming-dreaming-pancake`) で進行しているが、**Step 6 で `plugins/totto2727-coding/` を worktree 内に作成しても、新セッションで Claude Code を main checkout で起動するまで認識されない可能性がある**
- 暫定対策案:
  - PR をマージし main checkout を最新化してから新セッションで動作確認 (Validator Step 8)
  - もしくは worktree 内のファイルを main checkout 側にも同期する仕組みを導入 (現状の運用が既にそうなっている可能性あり、要確認)
- **本観点の推奨**: Validator (Step 8) が `Success criteria 2 (新パス実在の検証)` を main checkout で実行することを Task Plan に明記する

### Implications #5: 既存 `dev-workflow` プラグインを直接の前例とせよ

- Architect (Step 3) は `plugins/totto2727-coding/` の構造設計時、**`plugins/dev-workflow/` を直接の参照先**とすること:
  - `.claude-plugin/plugin.json` フォーマット (`plugins/dev-workflow/.claude-plugin/plugin.json:1-11`)
  - `skills/<skill-name>/SKILL.md` 配置 (`plugins/dev-workflow/skills/dev-workflow/SKILL.md` 等)
  - `agents/` 配下に subagent を置くパターン (`plugins/dev-workflow/agents/`)
- `plugins/totto2727-coding/.script/` (Deno 生成スクリプト) や `plugins/totto2727-coding/.claude/skills/` (slash command) も既存 `plugins/moonbit/.script/` / `plugins/moonbit/.claude/skills/` に倣えばよい

### Intent Spec Open Question #1 への回答 (確定)

「dotfiles 側 registry 更新の要否」 → **不要**。本リポジトリ `.claude-plugin/marketplace.json` 更新と project `.claude/settings.json` の `enabledPlugins` 追加で完結する。Intent Spec Out of scope 条項 (`intent-spec.md:131-134`) は維持可能。**Blocker は解消**。

### Intent Spec Open Question #2 への回答 (確定)

「`.agents/skills-lock.json` における新プラグインの登録形式」 → **登録自体が不要 (Implications #2 参照)**。Claude Code 本体は lock を読まない。Cursor/Codex 用途を別サイクルで扱う場合のみ将来検討。

## Remaining unknowns

- **要ユーザー確認 (Architect Step 3 で Main 経由)**: Intent Spec Scope.4 (`.agents/skills-lock.json` 更新) と SC-5 (lock 検証) は技術的に不要なので撤回してよいか否か。撤回しない場合は方式 A (dotfiles 側追加) を別サイクルとして立てる必要がある (Implications #2 / #3)
- **要動作確認 (Validator Step 8)**: 新規 `plugins/totto2727-coding/` を main checkout に配置後、新セッションで Claude Code が `totto2727-coding:coding` 等の skill を available skills として認識するか (Implications #4)。これが SC の実質的な検証になる
- **`installed_plugins.json` の自動更新タイミング**: `.claude-plugin/marketplace.json` に新プラグインを追加した後、`~/.claude/plugins/installed_plugins.json` に `totto2727-coding@totto2727` エントリが自動追加されるか、それとも `/plugin install totto2727-coding@totto2727` または trust prompt 受諾が必要か。公式ドキュメントは「prompted to install」と記述しており **手動承諾が必要な可能性が高い** が、現セッションの dev-workflow が `installedAt: 2026-04-26` で記録されている事実から、過去のユーザー操作の履歴が引き継がれることが分かる。Validator Step 8 で実機確認を推奨
- **`enabledPlugins` のエントリのみ追加した場合の挙動**: project `.claude/settings.json` の `enabledPlugins` に `"totto2727-coding@totto2727": true` を追加してから新セッションを起動した場合、trust 済 project では即座に有効化されるのか / 改めてプロンプトが出るのかは未検証 (公式仕様は trust 時の prompt のみ言及)
- **`marketplaceKind` 欠落の現行 lock の挙動**: 先行 Note Remaining unknowns で指摘されている通り、`c-plugin sync` 実行時に `marketplaceKind` 不在エントリがどう扱われるかは未検証。ただし本観点の結論 (lock 自体が不要) を採用する場合、本観点としては優先度低
