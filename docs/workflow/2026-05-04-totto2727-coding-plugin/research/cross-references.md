# Research Note: cross-references

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Topic:** cross-references (旧スキル参照のハードコード箇所)
- **Researcher:** researcher (cross-references perspective)
- **Created at:** 2026-05-04
- **Scope:** リポジトリ全体および user CLAUDE.md における旧スキル / 旧プラグインパス参照の全件列挙、および移行対象スキル本文内 cross-reference の抽出。Intent Spec の成功基準 #6 (ハードコードパス参照不残) と Open Question #5 (CLAUDE.md 追記要否) の解消材料を提供する。

## Subject of investigation

本リサーチが扱う範囲:

1. **キーワードスキャン (リポジトリ全体)**: `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `moonbit-bestpractice` / `moonbit-docs` / `components-build-docs` / `plugins/moonbit/` / `plugins/components-build/` / `.agents/skills/` の各キーワードを `*.md` / `*.json` / `*.ts` / `*.tsx` / `*.js` / `*.yaml` / `*.yml` / `*.toml` 全体に対して `grep -rn` で検索。
2. **user CLAUDE.md (`/Users/totto2727/.claude/CLAUDE.md`) スキャン**: 同キーワードの言及有無を確認。
3. **移行対象スキル本文 (effect-\* / totto2727-fp / moonbit-bestpractice / moonbit-docs / components-build-docs) 内の Markdown link 抽出**: `[..](../...)` 形式を全件抽出し、移行で書き換えが必要か判定。
4. **CLAUDE.md (project / user) への新プラグイン情報追記要否の判定材料**: 既存記述パターン・auto-discovery 仕組みから根拠を提示。

本リサーチが扱わない範囲 (他観点):

- `.agents/skills-lock.json` の schema / loader 実装の詳細 (Open Question 2: 別観点で扱う)
- dotfiles 側 registry 更新の要否 (Open Question 1: 別観点で扱う)
- `coding/SKILL.md` の構造設計 (Open Question 3, 4: Architect が判断)

raw 結果は同ディレクトリ配下の `cross-references-raw-*.txt` に保存済み。

## Findings

### F-1. プロジェクト CLAUDE.md (`./CLAUDE.md`) と user CLAUDE.md (`/Users/totto2727/.claude/CLAUDE.md`) には旧スキル / 旧プラグインへの直接参照が一切存在しない

- 検索対象キーワード: `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `moonbit-bestpractice` / `moonbit-docs` / `components-build-docs` / `plugins/moonbit` / `plugins/components-build` / `.agents/skills`
- 結果: 両 CLAUDE.md とも該当行ゼロ (`grep` exit=1)
- Intent Spec の "Out of scope" 末尾の前提 (「現状 CLAUDE.md には effect-\* スキル等への直接参照は確認されていない」) は事実と一致。

### F-2. dev-workflow プラグインがスキル名 `effect-layer` 等を**プレースホルダ用例として**多数言及している

`raw-effect-layer.txt` / `raw-effect-runtime.txt` / `raw-effect-hono.txt` / `raw-totto2727-fp.txt` の重複箇所:

| ファイル                                                          | 行     | 該当行 (要約)                                                                                                                                    |
| ----------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `plugins/dev-workflow/README.md`                                  | L305   | `project-specific design conventions live in skills like \`effect-layer\`, \`effect-runtime\`, \`effect-hono\`, \`totto2727-fp\``                |
| `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`                | L297   | ``commands defer to project-specific skills** (`effect-layer`, `git-workflow`, …)``                                                              |
| `plugins/dev-workflow/skills/step-roadmap-decomposition/SKILL.md` | L45    | ``Paths of relevant project-specific skills (e.g. `effect-layer`, `git-workflow`, …)``                                                           |
| `plugins/dev-workflow/skills/specialist-architect/SKILL.md`       | L64    | ``If project-specific design skills exist (e.g., `effect-layer` / `effect-runtime` / `effect-hono`)``                                            |
| `plugins/dev-workflow/agents/implementer.md`                      | L37    | ``Project-specific implementation conventions (refer to skills such as `effect-layer`, `git-workflow`, etc.)``                                   |
| `plugins/dev-workflow/skills/dev-workflow/SKILL.md`               | L85    | ``owned by project-specific skills** (e.g. `effect-layer`, `git-workflow`, project CLAUDE.md)``                                                  |
| `plugins/dev-workflow/skills/dev-workflow/SKILL.md`               | L181   | ``project-specific skills (e.g. `effect-layer`, `git-workflow`, `macos-cli-rules`)``                                                             |
| `plugins/dev-workflow/skills/step-design/SKILL.md`                | L8     | ``skills (e.g. `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`)``                                                                |
| `plugins/dev-workflow/skills/step-design/SKILL.md`                | L35    | 同上 (Specific Inputs セクション)                                                                                                                |
| `plugins/dev-workflow/skills/specialist-common/SKILL.md`          | L41-42 | ``relevant skills: `effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp`, `git-workflow`, `macos-cli-rules`, etc.; varies by project`` |
| `plugins/dev-workflow/skills/specialist-implementer/SKILL.md`     | L62    | ``If project-specific skills (e.g., `effect-layer` / `effect-runtime` / `effect-hono` / `git-workflow`) exist``                                  |
| `plugins/dev-workflow/skills/step-implementation/SKILL.md`        | L40    | ``Project-specific skills paths (e.g. `effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp`, `git-workflow`, `macos-cli-rules`)``      |

これらはすべて **「プロジェクト固有スキルの例示 (placeholder)」** として inline-code で書かれており、「スキル名」を直接コードリンクや path として参照していない (パスが書かれていない)。本サイクルの新プラグイン化で**スキル名そのものは消滅**する (移行先は `coding/references/ts-effect-layer.md` 等のファイル名にリネーム)。

### F-3. ADR 2 件が `effect-layer` / `effect-runtime` 等を歴史的記録として参照している (immutable)

| ファイル                                                             | 行  | 該当行                                                                                                                          |
| -------------------------------------------------------------------- | --- | ------------------------------------------------------------------------------------------------------------------------------- |
| `docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md` | L9  | `researcher が言語固有スキル (effect-layer / totto2727-fp / vite-plus 等) を能動的に棚卸しした`                                 |
| `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md`             | L75 | ``Project-specific skill integration (`effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`, `git-workflow`, etc.).`` |

ADR は記録の不変性が原則。

### F-4. `js/package/fp/` の README.md と CLAUDE.md は旧スキル直リンク URL / パスを参照している

| ファイル                  | 行  | 該当行                                                                                                 | リンク先実体                                                                             |
| ------------------------- | --- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `js/package/fp/README.md` | L5  | `[SKILL.md](https://github.com/totto2727-org/monorepo/blob/main/.claude/skills/totto2727-fp/SKILL.md)` | GitHub URL: `main`ブランチの `.claude/skills/totto2727-fp/SKILL.md` (symlink 経由のパス) |
| `js/package/fp/CLAUDE.md` | L3  | `[SKILL.md](../../../.claude/skills/totto2727-fp/SKILL.md)`                                            | リポジトリ内 relative path: `.claude/skills/totto2727-fp/SKILL.md`                       |

補足: `.claude/skills/totto2727-fp` は `.agents/skills/totto2727-fp` への symlink (c-plugin 管理、`docs/adr/2026-04-06-c-plugin-skill-target.md` 参照)。新プラグイン化で `.agents/skills/totto2727-fp` 実体が削除されると symlink 先が消滅し、上記 2 行のリンクは**両方ともリンク切れ**になる。

### F-5. `.agents/skills-lock.json` と `.claude-plugin/marketplace.json` に旧プラグインが登録されている

| ファイル                          | 行  | 該当行                                                      |
| --------------------------------- | --- | ----------------------------------------------------------- |
| `.agents/skills-lock.json`        | L7  | `"enabledSkills": ["moonbit-bestpractice", "moonbit-docs"]` |
| `.agents/skills-lock.json`        | L9  | `"path": "./plugins/moonbit"`                               |
| `.agents/skills-lock.json`        | L12 | `"enabledSkills": ["components-build-docs"]`                |
| `.agents/skills-lock.json`        | L14 | `"path": "./plugins/components-build"`                      |
| `.claude-plugin/marketplace.json` | L16 | `"source": "./plugins/moonbit"`                             |
| `.claude-plugin/marketplace.json` | L20 | `"source": "./plugins/components-build"`                    |

`docs/adr/2026-04-06-c-plugin-cli-tool.md:105-106` も旧 `./plugins/moonbit` を例示しているが、ADR は immutable (F-3 同様)。

### F-6. 移行対象スキル本文内の cross-reference (相対 Markdown link)

#### F-6-A. effect-\* スキル間の兄弟リンク (本サイクルで書き換え必須)

| ファイル                                 | 行  | 該当リンク                                                                                 |
| ---------------------------------------- | --- | ------------------------------------------------------------------------------------------ |
| `.agents/skills/effect-layer/SKILL.md`   | L16 | `[effect-runtime](../effect-runtime/SKILL.md)`, `[effect-hono](../effect-hono/SKILL.md)`   |
| `.agents/skills/effect-runtime/SKILL.md` | L15 | `[effect-layer](../effect-layer/SKILL.md)`, `[effect-hono](../effect-hono/SKILL.md)`       |
| `.agents/skills/effect-hono/SKILL.md`    | L16 | `[effect-layer](../effect-layer/SKILL.md)`, `[effect-runtime](../effect-runtime/SKILL.md)` |

新構造では effect-\* 3 つは同一の `coding/references/` 配下の兄弟ファイル (`ts-effect-layer.md` / `ts-effect-runtime.md` / `ts-effect-hono.md`) になるため、リンクは `[ts-effect-runtime](./ts-effect-runtime.md)` 形式 (もしくは `[…](../ts-effect-runtime.md)` ではなく**同階層**) に書き換える必要がある。

#### F-6-B. effect-\* スキル本文からの ソースコード参照 (相対パス、書き換え必須)

| ファイル                                 | 行   | 該当リンク (旧 base: `.agents/skills/effect-*/`)                                                                                                                 |
| ---------------------------------------- | ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.agents/skills/effect-layer/SKILL.md`   | L74  | `[env.ts](../../js/app/saas-example/src/feature/env.ts)`                                                                                                         |
| `.agents/skills/effect-layer/SKILL.md`   | L75  | `[kysely.ts](../../js/app/saas-example/src/feature/db/kysely.ts)`                                                                                                |
| `.agents/skills/effect-layer/SKILL.md`   | L76  | `[better-auth.ts](../../js/app/saas-example/src/feature/auth/better-auth.ts)`                                                                                    |
| `.agents/skills/effect-runtime/SKILL.md` | L43  | `[runtime/server.ts](../../js/app/saas-example/src/feature/runtime/server.ts)`                                                                                   |
| `.agents/skills/effect-runtime/SKILL.md` | L44  | `[runtime/hono.ts](../../js/app/saas-example/src/feature/runtime/hono.ts)`                                                                                       |
| `.agents/skills/effect-hono/SKILL.md`    | L61  | `[auth/middleware.ts](../../js/app/saas-example/src/feature/auth/middleware.ts)`                                                                                 |
| `.agents/skills/effect-hono/SKILL.md`    | L87  | `[auth/app.ts](../../js/app/saas-example/src/feature/auth/app.ts)`                                                                                               |
| `.agents/skills/effect-hono/SKILL.md`    | L88  | `[entry.hono.ts](../../js/app/saas-example/src/entry.hono.ts)`                                                                                                   |
| `.agents/skills/effect-hono/SKILL.md`    | L106 | `[http/error.ts](../../js/app/saas-example/src/feature/http/error.ts)`                                                                                           |
| `.agents/skills/effect-hono/SKILL.md`    | L117 | `[entry.hono.ts](../../js/app/saas-example/src/entry.hono.ts)` (再掲、Middleware Order 節)                                                                       |
| `.agents/skills/effect-hono/SKILL.md`    | L118 | `[context.ts](../../js/app/saas-example/src/feature/share/lib/hono/context.ts)`, `[factory.ts](../../js/app/saas-example/src/feature/share/lib/hono/factory.ts)` |

旧 base (`.agents/skills/effect-*/`) からは `../..` で repo root に到達 (深さ 2)。新 base (`plugins/totto2727-coding/skills/coding/references/`) からは `../../../../..` で repo root に到達 (深さ 5)。書き換え対応:

- 旧: `(../../js/app/saas-example/src/feature/env.ts)`
- 新: `(../../../../../js/app/saas-example/src/feature/env.ts)` (深さを 2 → 5 に変更)

#### F-6-C. moonbit-bestpractice / moonbit-docs 兄弟リンク (本サイクルで書き換え必須)

| ファイル                                               | 行  | 該当リンク                                                 |
| ------------------------------------------------------ | --- | ---------------------------------------------------------- |
| `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md` | L12 | `[moonbit-docs](../moonbit-docs/SKILL.md)`                 |
| `plugins/moonbit/skills/moonbit-docs/SKILL.md`         | L17 | `[moonbit-bestpractice](../moonbit-bestpractice/SKILL.md)` |

**問題**: 新構造では `mbt-bestpractice.md` は `coding/references/` と `test/references/` に**分割移植**される。一方 `moonbit-docs/` は別スキルとして独立 (`plugins/totto2727-coding/skills/moonbit-docs/`)。よって兄弟関係が崩れる:

- `plugins/totto2727-coding/skills/moonbit-docs/SKILL.md` から `mbt-bestpractice` を参照する場合の新リンク: `[mbt-bestpractice](../coding/references/mbt-bestpractice.md)` (skill 跨ぎ参照)
- `plugins/totto2727-coding/skills/coding/references/mbt-bestpractice.md` 内の `moonbit-docs` 参照 (もし残すなら): `[moonbit-docs](../../moonbit-docs/SKILL.md)`

`moonbit-bestpractice/SKILL.md:L311` の `[MoonBit Testing Standards](./references/moonbit-test.md)` も書き換え必須:

- 旧: `./references/moonbit-test.md` (`moonbit-bestpractice/` 配下)
- 新: テスト規約は `test/references/mbt-bestpractice.md` に分離されるため、`coding/references/mbt-bestpractice.md` (コーディング規約パート) からは `[MoonBit Testing Standards](../../test/references/mbt-bestpractice.md)` を指す。

#### F-6-D. moonbit-docs/SKILL.md 内の 26 件の `[..](./references/<file>.md)` リンク (構造維持で**書き換え不要**)

`plugins/moonbit/skills/moonbit-docs/SKILL.md:L288-L313` に 26 件の `[..](./references/<file>.md)` リンクがある (例: `[language-fundamentals-built-in-data-structures.md](./references/language-fundamentals-built-in-data-structures.md)`)。Intent Spec で `moonbit-docs/` は構造ごと移行されるため、このリンク群は**書き換え不要**。

#### F-6-E. moonbit-docs/references/ 配下の `../...` リンク (元々リンク切れ、書き換え不要)

`raw-skill-names.txt` に出ない以下のリンク (本来は MoonBit 公式 docs 内の relative path):

- `language-attributes.md:L253,L279` → `../toolchain/moon/package.md#…`
- `toolchain-vscode-index.md:L28,L36,L48` → `../../language/fundamentals.md`, `../../language/error_codes/E0011.md`, `../../language/tests.md`
- `language-fundamentals-built-in-data-structures.md:L188` → `../toolchain/vscode/index.md`
- `toolchain-wasm-index.md:L19` → `../../language/ffi.md`
- `language-error-handling.md:L12` → `../tutorial/tour.md`
- `language-ffi.md:L52,L56,L324` → `../toolchain/moon/package.md#…`
- `language-packages.md:L15-L345` (多数) → `../toolchain/moon/package.md#…`, `../toolchain/moon/module.md#…`
- `language-async-experimental.md:L24` → `../tutorial/cli-quickstart.md`

これらは MoonBit 公式 docs (https://github.com/moonbitlang/moonbit-docs) 内のパスを生成スクリプト (`process-moonbit-docs.ts`) がそのまま転記したもの。リポジトリ内の実体は存在せず、**元々リンク切れ**。本サイクルでは**触らない** (Intent Spec の「移行はリネームと相対パス調整のみ。規約の中身 (ライセンスヘッダ含む) は別サイクル」の方針に従う)。

#### F-6-F. moonbit-docs/references/language-error-codes-index.md:L15

`[moonbitlang/moonbit-docs](https://github.com/moonbitlang/moonbit-docs)` は外部 URL (絶対 URL)。書き換え不要。

#### F-6-G. components-build-docs/SKILL.md:L43

`[vercel-composition-patterns](https://raw.githubusercontent.com/vercel-labs/agent-skills/refs/heads/main/skills/composition-patterns/SKILL.md)` は外部 URL。書き換え不要。

#### F-6-H. effect-\* / totto2727-fp の **frontmatter `name:` フィールド**

| ファイル                                                         | 行  | 該当行                        |
| ---------------------------------------------------------------- | --- | ----------------------------- |
| `.agents/skills/effect-layer/SKILL.md`                           | L2  | `name: effect-layer`          |
| `.agents/skills/effect-runtime/SKILL.md`                         | L2  | `name: effect-runtime`        |
| `.agents/skills/effect-hono/SKILL.md`                            | L2  | `name: effect-hono`           |
| `.agents/skills/totto2727-fp/SKILL.md`                           | L2  | `name: totto2727-fp`          |
| `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md`           | L2  | `name: moonbit-bestpractice`  |
| `plugins/moonbit/skills/moonbit-docs/SKILL.md`                   | L2  | `name: moonbit-docs`          |
| `plugins/components-build/skills/components-build-docs/SKILL.md` | L2  | `name: components-build-docs` |

新ファイル名は `ts-effect-layer.md` 等になるが、Claude Code の skill 認識は frontmatter の `name:` で行われる (Intent Spec の Scope 内では「reference files」扱いになるため `name:` は不要かも)。Architect 判断対象 (Open Question 3 と関連)。

### F-7. 生成スクリプトとスラッシュコマンド内のハードコードパス

| ファイル                                                                  | 行   | 該当行                                                                          | 対応           |
| ------------------------------------------------------------------------- | ---- | ------------------------------------------------------------------------------- | -------------- |
| `plugins/moonbit/.script/process-moonbit-docs.ts`                         | L22  | `const outputDir = join(projectRoot, 'skills', 'moonbit-docs')`                 | パス維持で不要 |
| `plugins/moonbit/.script/process-moonbit-docs.ts`                         | L132 | `[moonbit-bestpractice](../moonbit-bestpractice/SKILL.md)` (生成テンプレート内) | 書き換え必須   |
| `plugins/moonbit/.script/process-moonbit-docs.ts`                         | L135 | `name: moonbit-docs` (生成テンプレート内 frontmatter)                           | パス維持で不要 |
| `plugins/moonbit/.claude/skills/update-moonbit-docs.md`                   | L23  | `deno run … .script/process-moonbit-docs.ts` (CLI コマンド)                     | パス変更検討   |
| `plugins/moonbit/.claude/skills/update-moonbit-docs.md`                   | L26  | `Confirm SKILL.md was generated in skills/moonbit-docs/`                        | パス維持で不要 |
| `plugins/components-build/.script/generate-skill.ts`                      | L14  | `const outputDir = join(projectRoot, 'skills', 'components-build-docs')`        | パス維持で不要 |
| `plugins/components-build/.script/generate-skill.ts`                      | L115 | `name: components-build-docs` (生成テンプレート内 frontmatter)                  | パス維持で不要 |
| `plugins/components-build/.claude/skills/update-components-build-docs.md` | L20  | `Confirm skills/components-build-docs/SKILL.md was generated`                   | パス維持で不要 |

スクリプト内の `projectRoot` は `import.meta` 等で算定される想定 — 移行先 (`plugins/totto2727-coding/.script/`) でも同名サブディレクトリ (`skills/moonbit-docs/`) を出力するなら本体ロジックは不変。Intent Spec の Scope 3 表で「(出力先パス書き換え)」と記載されているのは念のための明示と解釈。

`process-moonbit-docs.ts:L132` の `[moonbit-bestpractice](../moonbit-bestpractice/SKILL.md)` は**生成スクリプトが書き出すリンク**で、新構造では兄弟関係が崩れる (F-6-C と同じ問題) ため、テンプレート文字列の書き換えが必須。

### F-8. `.agents/skills/` 経由の symlink 構造

`.agents/skills/components-build-docs` と `.agents/skills/moonbit-bestpractice` は dotfiles 由来の symlink (`../.cache/totto2727-dotfiles/agents/plugins/...`)、`.agents/skills/effect-*` と `.agents/skills/totto2727-fp` は実体ファイル。`.claude/skills/effect-*` / `totto2727-fp` は `.agents/skills/` への symlink (c-plugin 管理)。

→ symlink 構造の制御は c-plugin (`.agents/skills-lock.json` 経由) が握っているため、新プラグイン登録時に lock 更新で symlink が再生成される想定。本観点では symlink 自体は対象外 (Open Question 2 の領域)。

### F-9. `mbt/package/geo/CLAUDE.md:L35` の `@SKILL.md` 参照

該当行: `For MoonBit coding conventions, see @SKILL.md`

`@`-prefix は Claude Code の特殊 syntax (skill auto-load を意図する省略表記) と推測される。`mbt/package/geo/` ディレクトリには `SKILL.md` が存在しないため、これは**暗黙的に `moonbit-bestpractice` 等を指す省略表記**もしくは**リンク切れ記述**と思われる。本観点ではこれを「グレーゾーン」として扱い、Architect への申し送り事項とする (CLAUDE.md 更新方針と関わる)。

## Sources

- 全 grep raw 結果:
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-effect-layer.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-effect-runtime.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-effect-hono.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-totto2727-fp.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-plugins-moonbit.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-plugins-components-build.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-skill-names.txt`
  - `docs/workflow/2026-05-04-totto2727-coding-plugin/research/cross-references-raw-agents-skills.txt`
- 移行対象スキル本文 (read 確認):
  - `.agents/skills/effect-layer/SKILL.md`
  - `.agents/skills/effect-runtime/SKILL.md`
  - `.agents/skills/effect-hono/SKILL.md`
  - `.agents/skills/totto2727-fp/SKILL.md`
  - `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md`
  - `plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md`
  - `plugins/moonbit/skills/moonbit-docs/SKILL.md`
  - `plugins/components-build/skills/components-build-docs/SKILL.md`
- 関連ファイル:
  - `js/package/fp/README.md:L5`
  - `js/package/fp/CLAUDE.md:L3`
  - `mbt/package/geo/CLAUDE.md:L35`
  - `CLAUDE.md` (project root)
  - `/Users/totto2727/.claude/CLAUDE.md` (user global)
  - `.agents/skills-lock.json:L7,L9,L12,L14`
  - `.claude-plugin/marketplace.json:L16,L20`
- 関連 ADR (immutable、参考のみ):
  - `docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md:L9`
  - `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md:L75`
  - `docs/adr/2026-04-06-c-plugin-cli-tool.md:L105-L106`
  - `docs/adr/2026-04-06-c-plugin-skill-target.md` (.claude/skills symlink の仕組み)

## Implications for design

### IMPL-1. 移行で**書き換え必須**な参照リスト (Implementer 消化対象)

以下を Implementer が新パスに合わせて書き換える。

#### IMPL-1-A. 移行対象スキル本文内の cross-reference (新ファイルへ転記する際に書き換え)

**effect-\* スキル間の兄弟リンク** (旧: `[xxx](../<skill>/SKILL.md)` → 新: `[xxx](./ts-<skill>.md)` または `[xxx](<skill>.md)`):

- `coding/references/ts-effect-layer.md` 内: `effect-runtime` / `effect-hono` への参照
- `coding/references/ts-effect-runtime.md` 内: `effect-layer` / `effect-hono` への参照
- `coding/references/ts-effect-hono.md` 内: `effect-layer` / `effect-runtime` への参照

**effect-\* スキル本文からのソースコード参照** (深さ 2 → 5 への調整):

- `coding/references/ts-effect-layer.md`: `env.ts` / `kysely.ts` / `better-auth.ts` (3 件) → `../../../../../js/app/saas-example/src/feature/...`
- `coding/references/ts-effect-runtime.md`: `runtime/server.ts` / `runtime/hono.ts` (2 件)
- `coding/references/ts-effect-hono.md`: `auth/middleware.ts` / `auth/app.ts` / `entry.hono.ts` (×2) / `http/error.ts` / `context.ts` / `factory.ts` (7 件)

**moonbit-bestpractice 関連の構造変更による書き換え**:

- `coding/references/mbt-bestpractice.md` (旧 `moonbit-bestpractice/SKILL.md`) 内:
  - L12 `[moonbit-docs](../moonbit-docs/SKILL.md)` → `[moonbit-docs](../../moonbit-docs/SKILL.md)` (skill 跨ぎ)
  - L311 `[MoonBit Testing Standards](./references/moonbit-test.md)` → テスト規約は別ファイルへ分離されるため、参照ターゲット要再判定 (`../../test/references/mbt-bestpractice.md` を指すか、リンク自体を削除するかは Architect 判断)
- `moonbit-docs/SKILL.md` (新パス: `plugins/totto2727-coding/skills/moonbit-docs/SKILL.md`) 内:
  - L17 `[moonbit-bestpractice](../moonbit-bestpractice/SKILL.md)` → `[mbt-bestpractice](../coding/references/mbt-bestpractice.md)` (skill 跨ぎ)

#### IMPL-1-B. 生成スクリプトテンプレート文字列の書き換え

- `plugins/totto2727-coding/.script/process-moonbit-docs.ts:L132` (旧 `plugins/moonbit/.script/process-moonbit-docs.ts:L132`) の生成テンプレート内文字列 `[moonbit-bestpractice](../moonbit-bestpractice/SKILL.md)` → `[mbt-bestpractice](../coding/references/mbt-bestpractice.md)` 等に書き換え (ただし出力先 `moonbit-docs/SKILL.md` は新構造でも残るため、出力テンプレートも IMPL-1-A の `moonbit-docs/SKILL.md:L17` と同じ書き換えを適用)。

#### IMPL-1-C. `js/package/fp/README.md` と `js/package/fp/CLAUDE.md` の書き換え

- `js/package/fp/README.md:L5`: `https://github.com/totto2727-org/monorepo/blob/main/.claude/skills/totto2727-fp/SKILL.md` → 新 GitHub URL: `https://github.com/totto2727-org/monorepo/blob/main/plugins/totto2727-coding/skills/coding/references/ts-totto2727-fp.md`
- `js/package/fp/CLAUDE.md:L3`: `[SKILL.md](../../../.claude/skills/totto2727-fp/SKILL.md)` → `[SKILL.md](../../../plugins/totto2727-coding/skills/coding/references/ts-totto2727-fp.md)` (相対パス) もしくは `coding/SKILL.md` を指すよう整理

#### IMPL-1-D. `.agents/skills-lock.json` と `.claude-plugin/marketplace.json` の書き換え

- `.agents/skills-lock.json`: `plugins/moonbit` / `plugins/components-build` エントリを削除し、`totto2727-coding` プラグインを追加 (Intent Spec Scope 4)
- `.claude-plugin/marketplace.json:L11-L21`: 旧 2 プラグインエントリ削除、`totto2727-coding` 追加

#### IMPL-1-E. dev-workflow プラグイン本体内の placeholder 言及 (任意、ただし強く推奨)

F-2 の 12 箇所は現在「`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp`」を**プロジェクト固有スキル名の例示**として使っている。本サイクルでこれらのスキル名は廃止される (新名: `coding` / `test` の references)。よって以下のいずれかが必要:

- (a) すべての例示を `coding` / `test` (新スキル名) に置換する (12 箇所、機械的)
- (b) 「過去のスキル名」のままにし、Architect が dev-workflow 側の更新は別サイクルで扱うと判断する

**推奨**: (a) を本サイクル内で実施 (Intent Spec 成功基準 #6 「ハードコードパス参照不残」を厳格に解釈すれば、スキル名そのものの参照も対象とすべき)。Architect の判断対象。

### IMPL-2. **書き換え不要**な参照 (移行で残してよい / 偽陽性扱い)

- **ADR 2 件** (F-3、historical record として immutable)
- **moonbit-docs/references/ 配下の死リンク** (F-6-E、元々 MoonBit 公式 docs 由来のリンク切れ。Intent Spec 「規約の中身は別サイクル」方針に従い触らない)
- **moonbit-docs/SKILL.md:L288-L313 の 26 件 references リンク** (F-6-D、構造維持で書き換え不要)
- **components-build-docs/SKILL.md:L43 の外部 URL** (F-6-G)
- **moonbit-docs/references/language-error-codes-index.md:L15 の外部 URL** (F-6-F)
- **生成スクリプト本体内 path 計算ロジック** (F-7、`projectRoot + 'skills' + 'moonbit-docs'` 等は新プラグインでも同名サブディレクトリ出力のため不変)
- **`.claude-plugin/marketplace.json` の `dev-workflow` / `totto2727` エントリ** (今回スコープ外プラグイン)

### IMPL-3. CLAUDE.md (project / user) への新プラグイン情報の追記要否

#### 結論: **追記不要** (ただし `mbt/package/geo/CLAUDE.md:L35` の `@SKILL.md` 解決は要 Architect 判断)

#### 根拠

1. **既存 CLAUDE.md は旧スキル / 旧プラグインを一切名指ししていない** (F-1)。これは Claude Code が `.claude-plugin/marketplace.json` + `.agents/skills-lock.json` + skill frontmatter (`name:` / `description:`) からの**自動 discovery** で skill を提示する設計と整合。CLAUDE.md は「リポジトリ全体の操作規約」のみを記述する役割。
2. **Intent Spec の Out of scope 末尾も「現状 CLAUDE.md には effect-\* スキル等への直接参照は確認されていない」と明記**しており、これは F-1 の調査結果と一致。新プラグイン化後も同じ自動 discovery 経路で検出されるため、CLAUDE.md に明示参照を追加する積極的な必要性はない。
3. **CLAUDE.md (project root) のメンテナンスコスト削減の観点**: スキル一覧を CLAUDE.md に書くと、新スキル追加・既存スキル変更のたびに手動更新が必要となり、`.claude-plugin/marketplace.json` (master of truth) との二重管理が発生する。

#### 例外 (Architect 判断委譲)

- **`mbt/package/geo/CLAUDE.md:L35` の `@SKILL.md` は何らかのリンク解決を期待している記述**。`mbt/package/geo/` 直下に `SKILL.md` は存在しないため、これは:
  - (a) `moonbit-bestpractice` (新: `coding/references/mbt-bestpractice.md`) を `@<skill-name>` 構文で参照する Claude Code 機能を使った記述、または
  - (b) 単なるリンク切れ (typo)
  - のいずれか。`mbt/package/geo/` の所有者 (totto2727 本人) に確認するか、`@coding` / `@<新スキル名>` への書き換えを Architect が判断する必要がある。

#### 補足: 追記する場合の最小限の追記内容案 (採用しない場合に削除可)

仮に追記する場合の最小案:

```markdown
## Coding Conventions

For language-specific coding/test conventions, see the `totto2727-coding` plugin (`plugins/totto2727-coding/`):

- Coding entry: `plugins/totto2727-coding/skills/coding/SKILL.md`
- Test entry: `plugins/totto2727-coding/skills/test/SKILL.md`
- External spec references: `plugins/totto2727-coding/skills/{moonbit-docs,components-build-docs}/SKILL.md`
```

ただし上記は IMPL-3 の結論「追記不要」と矛盾しない範囲で**Architect が必要と判断した場合のみ**採用 (1 件で済む)。

### IMPL-4. 成功基準 #6 (ハードコードパス参照不残) の Validator 観測手順への含意

成功基準 #6 を Step 8 で観測するための grep 候補は本リサーチで列挙済み (F 全件) であり、Validator は次の grep を実行して 0 件 (もしくは ADR / 旧プラグイン削除済みの状態) を確認すれば足りる:

- `grep -rn "plugins/moonbit\|plugins/components-build\|\.agents/skills/effect-\|\.agents/skills/totto2727-fp" . --include="*.md" --include="*.json" --include="*.ts" --exclude-dir=docs/adr --exclude-dir=node_modules --exclude-dir=.git --exclude-dir="docs/workflow"`
  - 期待結果: 0 件 (ADR 除外済み、ADR は immutable のため)
- `grep -rn "moonbit-bestpractice\|moonbit-docs\|components-build-docs" . --include="*.md" --include="*.json" --include="*.ts" --exclude-dir=docs/adr --exclude-dir=node_modules --exclude-dir=.git --exclude-dir="docs/workflow"`
  - 期待結果: 新プラグイン (`plugins/totto2727-coding/`) 配下のみ (移行先で `moonbit-docs` / `components-build-docs` のスキル名は維持される、`moonbit-bestpractice` は廃止スキル名なので 0 件)

ただし dev-workflow 本体での placeholder 言及 (F-2) を残す判断 (IMPL-1-E (b)) を採用する場合、`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` の grep は dev-workflow を除外する必要がある — Validator は grep 範囲の精緻化が必要。

## Remaining unknowns

### UQ-1. dev-workflow プラグイン本文中の旧スキル名 placeholder 言及 (12 箇所) を本サイクルで書き換えるか

- 現状: `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` を「プロジェクト固有スキルの例示」として inline-code で参照している
- 本サイクル内で書き換えるか (新スキル名は `coding` / `test`)、別サイクル送りにするかは Architect / Main 判断
- **影響**: 成功基準 #6 の検証 grep 範囲をどうするか直結する

### UQ-2. `mbt/package/geo/CLAUDE.md:L35` の `@SKILL.md` の正体

- `@`-prefix が Claude Code の特殊 syntax (skill auto-load) なのか、リンク切れ typo なのか不明
- 該当行が `For MoonBit coding conventions, see @SKILL.md` という文脈から、おそらく `moonbit-bestpractice` の自動 load を意図しているが、`mbt/package/geo/` には SKILL.md が存在しない
- **対応案**: Architect が以下のいずれかで判断:
  - (a) `mbt/package/geo/CLAUDE.md` を新パスに更新 (`@coding/references/mbt-bestpractice.md` 等)
  - (b) totto2727 本人に意図を確認するため Blocker 報告
  - (c) 本サイクル外として留保

### UQ-3. effect-\* / totto2727-fp の SKILL.md frontmatter `name:` フィールドの扱い

- 移行先は references/ ファイル (`ts-effect-layer.md` 等) 扱いのため、Claude Code の skill 認識は frontmatter 不要 (entry SKILL.md は `coding/SKILL.md` のみ) と推測
- 既存 frontmatter (`name: effect-layer` / `description: ...`) を新ファイルに保持するか、frontmatter ごと削除するかは Architect 判断 (Open Question 3 と関連)

### UQ-4. moonbit-docs/references/ 内の死リンク群を将来サイクルで修復するか

- 現状: MoonBit 公式 docs から自動生成されたリンク切れが多数 (F-6-E)
- 本サイクルでは「規約の中身は触らない」方針のため対象外
- 将来課題として retrospective に申し送り推奨 (本観点では言及のみ)
