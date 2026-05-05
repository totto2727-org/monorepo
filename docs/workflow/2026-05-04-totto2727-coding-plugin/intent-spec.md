# Intent Spec: Consolidate coding/test/docs skills into `totto2727-coding` plugin

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Author:** intent-analyst (dev-workflow Step 1) / Main (Step 2 後の前提変化反映)
- **Created at:** 2026-05-04
- **Last updated:** 2026-05-04 (rebase で取り込まれた `5e92483` を反映、`.agents/skills-lock.json` の議論削除、Cursor/Codex marketplace 対応を明記)

## Background

現在、totto2727 のコーディング規約・ベストプラクティス・外部仕様リファレンスに関する Skill / Plugin 資産が以下の通り分散しており、参照ポイントが複数存在することでメンテナンス負荷と探索コストが上がっている。

- `plugins/moonbit/` プラグイン
  - `skills/moonbit-bestpractice/` — MoonBit 言語のベストプラクティス (手書き、コーディング規約) + `references/moonbit-test.md` (テスト規約)
  - `skills/moonbit-docs/` — MoonBit 言語リファレンス 25+ ファイル (`.script/process-moonbit-docs.ts` で MoonBit 公式から自動生成、ライセンスヘッダ付き)
  - `.script/process-moonbit-docs.ts` — Deno 製生成スクリプト
  - `.claude/skills/update-moonbit-docs.md` — 上記を起動する slash command
  - `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` + `.cursor-plugin/plugin.json` — マルチプラットフォーム manifest (Claude / Codex / Cursor、`c-plugin dev marketplace sync` で自動同期される)
- `plugins/components-build/` プラグイン
  - `skills/components-build-docs/SKILL.md` — Vercel components-build 仕様リファレンス
  - `.script/generate-skill.ts` — 同スキルの自動生成スクリプト
  - `.claude/skills/update-components-build-docs.md` — slash command
  - `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` + `.cursor-plugin/plugin.json` — 同上
- `.agents/skills/` (プロジェクト直置き、プラグイン外)
  - `effect-layer/SKILL.md` — Effect Layer/Service 定義パターン (TypeScript)
  - `effect-runtime/SKILL.md` — Effect Layer 合成 + ManagedRuntime (TypeScript)
  - `effect-hono/SKILL.md` — Effect + Hono 統合 (TypeScript)
  - `totto2727-fp/SKILL.md` — `@totto2727/fp` パッケージ使用ガイド (TypeScript)
- ルート 3 種 marketplace ファイル — `.claude-plugin/marketplace.json` (Claude 用、編集 base) / `.cursor-plugin/marketplace.json` (Cursor 用、sync で派生) / `.agents/plugins/marketplace.json` (Codex 用、sync で派生)
- 旧 `.agents/skills-lock.json` および `.agents/skills/{moonbit-bestpractice,moonbit-docs,components-build-docs}` symlink は `5e92483` で削除済み (= 本サイクル開始時点ではまだ存在していたが、rebase で消滅)

これらは性質ごとに 2 種類に大別できる:

1. **コーディング規約・テスト規約** (手書き、totto2727 固有の流儀) — `moonbit-bestpractice` + effect-\* + totto2727-fp
2. **外部仕様リファレンス** (自動生成、第三者仕様の取り込み) — 新プラグイン内では `docs-*` 命名規則で統一 (`docs-moonbit` + `docs-components-build`)

これらが「totto2727 のコーディング流儀全般」という単一の関心事に属するにもかかわらず、複数のプラグイン / `.agents/skills/` 直置きという複数のオーナーシップに分散している状態が、Skill 活用時の「どこを参照すべきか」を不明瞭にしている。

## Purpose

totto2727 固有のコーディング規約 (言語非依存方針 + 言語別ベストプラクティス) とテスト規約、および totto2727 が日常的に参照する外部仕様リファレンス (MoonBit 言語仕様 / components-build 仕様) を、単一の `plugins/totto2727-coding` プラグイン配下に集約・再構成し、Skill 探索の単一エントリポイント (`coding/SKILL.md` および `test/SKILL.md`) を確立する。

## Scope

### 1. 新規プラグイン `plugins/totto2727-coding/` の作成

以下の構造で新規プラグインを作成する:

```
plugins/totto2727-coding/
├── .claude-plugin/plugin.json     ← 編集 base (1 ファイルのみ作成)
├── (.codex-plugin/plugin.json)    ← c-plugin dev marketplace sync で自動生成
├── (.cursor-plugin/plugin.json)   ← c-plugin dev marketplace sync で自動生成
├── .script/
│   ├── generate-docs-moonbit.ts
│   └── generate-docs-components-build.ts
├── .claude/
│   └── skills/
│       ├── update-docs-moonbit.md
│       └── update-docs-components-build.md
└── skills/
    ├── coding/
    │   ├── SKILL.md
    │   └── references/
    │       ├── ts-skill.md
    │       ├── ts-effect-layer.md
    │       ├── ts-effect-runtime.md
    │       ├── ts-effect-hono.md
    │       ├── ts-totto2727-fp.md
    │       ├── mbt-skill.md
    │       └── mbt-bestpractice.md
    ├── test/
    │   ├── SKILL.md
    │   └── references/
    │       ├── mbt-skill.md
    │       └── mbt-bestpractice.md
    ├── docs-moonbit/
    │   ├── SKILL.md
    │   └── references/
    │       └── (25+ 個の言語リファレンスファイル、構造維持)
    └── docs-components-build/
        └── SKILL.md
```

**Manifest 同期方針**: 編集対象は `.claude-plugin/plugin.json` (1 ファイル) のみ。`.codex-plugin/plugin.json` と `.cursor-plugin/plugin.json` は本サイクル最終タスクで `c-plugin dev marketplace sync` を 1 回実行することで base から自動生成される (実装: `js/app/c-plugin/src/service/marketplace-sync.ts`)。手作業で 3 ファイルを保守しない。

### 2. `coding/SKILL.md` および `test/SKILL.md` の新規作成

3 階層構造のエントリポイントとして:

- `SKILL.md` (300 行以内、hard cap)
  - 言語非依存の基本方針 (型安全性 / 副作用局所化 / 命名意図性 / テスト可能性 等の普遍原則)
  - 言語インデックス (`ts-skill.md` / `mbt-skill.md` 等への誘導)
  - 外部仕様リファレンス (`docs-moonbit` / `docs-components-build`) への誘導 (`coding/SKILL.md` のみ)
- `references/<lang>-skill.md` (中間目次)
  - その言語の個別トピック (`<lang>-*.md`) への索引と、各トピックを参照する状況の説明
  - **外部依存スキル参照** (= プラグイン外の関連スキル) を **スキル名のみ** で列挙する。パス構造は不安定 (例: `.agents/skills/<name>` ↔ `node_modules/<pkg>/skills/<name>` の symlink ↔ 別 plugin 配下) のため、リンクは張らずに「対象スキル名 + 用途」の形式で参照する
- `references/<lang>-*.md` (詳細)
  - 既存スキルの内容を移植 (リネームのみ、内容は基本維持)

#### 外部依存スキル参照 (本サイクル時点)

| 言語       | 中間目次                        | 参照する外部スキル | 用途                                                                            |
| ---------- | ------------------------------- | ------------------ | ------------------------------------------------------------------------------- |
| TypeScript | `coding/references/ts-skill.md` | `vite-plus`        | Vite+ unified toolchain (build / dev / monorepo orchestration、CLI)             |
| TypeScript | `coding/references/ts-skill.md` | `remix`            | Remix 3 アプリケーション (routes / controllers / middleware / hydration / etc.) |
| TypeScript | `test/references/ts-skill.md`   | `vite-plus`        | Vitest (vp test、テスト実行・関連テスト発見)                                    |

参照の書式 (Implementer 向けガイド):

```markdown
### 外部スキル参照

- `vite-plus` — Vite+ unified toolchain (Vite / Vitest / monorepo orchestration). 開発コマンド・CLI で利用
- `remix` — Remix 3 アプリ開発 (routes / controllers / middleware / hydration / 等)
```

Markdown link は張らない (パス不安定のため)。読者 (Claude) は **スキル名から auto-discovery で実体を解決**する。

### 3. 既存スキル / プラグインの移行 + 削除

| 移行元                                                                    | 移行先                                                                                                          |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `.agents/skills/effect-layer/SKILL.md`                                    | `plugins/totto2727-coding/skills/coding/references/ts-effect-layer.md`                                          |
| `.agents/skills/effect-runtime/SKILL.md`                                  | `plugins/totto2727-coding/skills/coding/references/ts-effect-runtime.md`                                        |
| `.agents/skills/effect-hono/SKILL.md`                                     | `plugins/totto2727-coding/skills/coding/references/ts-effect-hono.md`                                           |
| `.agents/skills/totto2727-fp/SKILL.md`                                    | `plugins/totto2727-coding/skills/coding/references/ts-totto2727-fp.md`                                          |
| `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md`                    | `plugins/totto2727-coding/skills/coding/references/mbt-bestpractice.md`                                         |
| `plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md`  | `plugins/totto2727-coding/skills/test/references/mbt-bestpractice.md`                                           |
| `plugins/moonbit/skills/moonbit-docs/` (構造ごと)                         | `plugins/totto2727-coding/skills/docs-moonbit/` (リネーム + frontmatter `name: docs-moonbit`)                   |
| `plugins/moonbit/.script/process-moonbit-docs.ts`                         | `plugins/totto2727-coding/.script/generate-docs-moonbit.ts` (リネーム + 出力先パス書き換え)                     |
| `plugins/moonbit/.claude/skills/update-moonbit-docs.md`                   | `plugins/totto2727-coding/.claude/skills/update-docs-moonbit.md` (リネーム + パス書き換え)                      |
| `plugins/components-build/skills/components-build-docs/` (構造ごと)       | `plugins/totto2727-coding/skills/docs-components-build/` (リネーム + frontmatter `name: docs-components-build`) |
| `plugins/components-build/.script/generate-skill.ts`                      | `plugins/totto2727-coding/.script/generate-docs-components-build.ts` (リネーム + 出力先パス書き換え)            |
| `plugins/components-build/.claude/skills/update-components-build-docs.md` | `plugins/totto2727-coding/.claude/skills/update-docs-components-build.md` (リネーム + パス書き換え)             |

移行完了後、以下を完全削除する:

- `plugins/moonbit/` (ディレクトリごと)
- `plugins/components-build/` (ディレクトリごと)
- `.agents/skills/effect-layer/`
- `.agents/skills/effect-runtime/`
- `.agents/skills/effect-hono/`
- `.agents/skills/totto2727-fp/`

#### スクリプト内部修正の必須事項 (リネームに伴う)

`docs-*` 命名規則への変更に伴い、各 Deno スクリプトと slash command の **内部参照** も書き換える:

**`generate-docs-moonbit.ts`** (旧 `process-moonbit-docs.ts`):

- ファイル名リネーム
- 出力先ハードコード: `outputDir = join(projectRoot, 'skills', 'moonbit-docs')` → `outputDir = join(projectRoot, 'skills', 'docs-moonbit')`
- 生成 SKILL.md の frontmatter `name:` テンプレート文字列: `name: moonbit-docs` → `name: docs-moonbit`
- 生成 SKILL.md の `Related Skills` リンク (relatedSkillsBlock 変数): 旧 `../moonbit-bestpractice/SKILL.md` → 新 `../coding/references/mbt-bestpractice.md`
- `import.meta.dirname` null guard を冒頭に追加 (SC-7 達成のため、`design.md` A6 参照)

**`generate-docs-components-build.ts`** (旧 `generate-skill.ts`):

- ファイル名リネーム
- 出力先ハードコード: `skills/components-build-docs/` → `skills/docs-components-build/`
- 生成 SKILL.md の frontmatter `name:` テンプレート文字列: `name: components-build-docs` → `name: docs-components-build`
- `import.meta.dirname` null guard を冒頭に追加

**`update-docs-moonbit.md`** (旧 `update-moonbit-docs.md`):

- ファイル名リネーム
- 内部 `deno run .script/process-moonbit-docs.ts` → `deno run .script/generate-docs-moonbit.ts`

**`update-docs-components-build.md`** (旧 `update-components-build-docs.md`):

- ファイル名リネーム
- 内部 `deno run .script/generate-skill.ts` (または旧名) → `deno run .script/generate-docs-components-build.ts`

実体スキルファイル (`docs-moonbit/SKILL.md`, `docs-components-build/SKILL.md`) の frontmatter `name:` も新名に更新するが、これは生成スクリプト次回実行時に自動的に再生成される (= スクリプト側のテンプレ修正が真のソース)。Step 6 では「スクリプト修正 + 1 回スクリプト実行で再生成」または「実体ファイルとスクリプトの両方を手動で同期」のいずれかを採る (`design.md` A8 で実装方針を確定)。

### 4. ルート marketplace.json と `.claude/settings.json` の更新

Claude Code が本リポジトリの新プラグインを認識するため (Research note `plugin-discovery-mechanism.md` で確定) 以下を更新:

- **`.claude-plugin/marketplace.json`** (編集 base):
  - `plugins[]` から `moonbit` / `components-build` エントリを削除
  - `plugins[]` に `{"name": "totto2727-coding", "source": "./plugins/totto2727-coding"}` を追加
- **`.cursor-plugin/marketplace.json`**, **`.agents/plugins/marketplace.json`**:
  - 編集不要。最終タスクで `c-plugin dev marketplace sync` を実行することで base から自動再生成される
- **`.claude/settings.json`** の `enabledPlugins`:
  - `"moonbit@totto2727": true` を削除
  - `"components-build@totto2727": true` を削除
  - `"totto2727-coding@totto2727": true` を追加

### 5. `c-plugin dev marketplace sync` の実行

本サイクルの **最終タスク** として 1 回実行。これにより以下が自動生成・更新される:

- `.cursor-plugin/marketplace.json` (Cursor 用、Claude/Cursor で同フォーマット)
- `.agents/plugins/marketplace.json` (Codex 用、`source.source: "local"` + `policy` フィールド付き)
- 各プラグイン (本サイクル対象は totto2727-coding) の `.codex-plugin/plugin.json` / `.cursor-plugin/plugin.json` (`.claude-plugin/plugin.json` が base)

旧プラグイン (`moonbit`, `components-build`) は base marketplace.json から削除済みのため、sync 後に派生 marketplace からも消える。プラグイン配下の旧 manifest はディレクトリごと削除されるため別途処理不要。

### 6. 命名規約

言語固有 references/ ファイルには以下の prefix を使用:

- `ts-` — TypeScript 専用 (Effect / totto2727-fp 等)
- `mbt-` — MoonBit
- `js-` — JavaScript 共通 (将来の拡張用に予約。本サイクルでは新規ファイル作成なし)

## Out of scope

- **dotfiles リポジトリ (`totto2727-dotfiles/agents`) 側の registry 更新**
  - Step 2 Research (`plugin-discovery-mechanism.md`) で確定: Claude Code は本リポジトリの marketplace.json を `extraKnownMarketplaces` 経由で直接読むため、dotfiles 側更新は本サイクルでは不要
  - 旧 `.agents/skills-lock.json` (Cursor/Codex 配布用の独立した別仕組み) は `5e92483` で本リポジトリから既に削除済 (本サイクル開始時点では存在していたが rebase で消滅)
  - 将来 Cursor/Codex から `totto2727-coding` を使う要件が明確になった場合は別サイクルで dotfiles を更新する
- **既存 SKILL.md / references/ 本文の規約内容そのものの大幅な改訂**
  - 移行はリネームと相対パス調整のみ。規約の中身 (例: Effect Layer 定義のベストプラクティス) は別サイクルで扱う
- **新規言語 (Go, Rust 等) の skill / references 追加**
  - `ts-` / `mbt-` 以外の言語は本サイクルでは作成しない
- **`coding/SKILL.md` / `test/SKILL.md` への大規模な新規方針 (Google style guide 風サマリ等) の書き起こし**
  - 「言語非依存の基本方針 + 言語の目次」を 300 行以内で記述するに留める
- **テスト規約の TypeScript 詳細 (`test/references/ts-*.md` 個別トピック詳細)**
  - 現状 TS テスト規約に該当する移行元スキル (の詳細本文) がないため、本サイクルでは個別 `ts-*.md` 詳細ファイルは作成しない (将来追加余地のみ確保)
  - ただし `test/references/ts-skill.md` (中間目次) は外部スキル参照 (`vite-plus`) を含めるため新規作成する
- **CLAUDE.md (project / user) への新プラグインのドキュメント追記**
  - 必要性は Step 2 / Step 3 で判断 (現状 CLAUDE.md には effect-\* スキル等への直接参照は確認されていない)

## Success criteria

すべて Validation Step 8 で観測可能な形で測定する。

1. **旧パス削除の検証** — 以下のパスが全て存在しないこと (`find` で非存在を確認):
   - `plugins/moonbit/`
   - `plugins/components-build/`
   - `.agents/skills/effect-layer/`
   - `.agents/skills/effect-runtime/`
   - `.agents/skills/effect-hono/`
   - `.agents/skills/totto2727-fp/`
2. **新パス実在の検証** — 以下のファイルが全て存在すること (ファイル実在チェック):
   - `plugins/totto2727-coding/.claude-plugin/plugin.json`
   - `plugins/totto2727-coding/skills/coding/SKILL.md`
   - `plugins/totto2727-coding/skills/test/SKILL.md`
   - `plugins/totto2727-coding/skills/docs-moonbit/SKILL.md`
   - `plugins/totto2727-coding/skills/docs-components-build/SKILL.md`
   - `plugins/totto2727-coding/skills/coding/references/{ts-skill,ts-effect-layer,ts-effect-runtime,ts-effect-hono,ts-totto2727-fp,mbt-skill,mbt-bestpractice}.md`
   - `plugins/totto2727-coding/skills/test/references/{ts-skill,mbt-skill,mbt-bestpractice}.md`
   - `plugins/totto2727-coding/.script/generate-docs-moonbit.ts`
   - `plugins/totto2727-coding/.script/generate-docs-components-build.ts`
   - `plugins/totto2727-coding/.claude/skills/update-docs-moonbit.md`
   - `plugins/totto2727-coding/.claude/skills/update-docs-components-build.md`
3. **SKILL.md 行数上限の検証** — `wc -l plugins/totto2727-coding/skills/coding/SKILL.md` と `wc -l plugins/totto2727-coding/skills/test/SKILL.md` が**それぞれ 300 行以下**であること
4. **3 階層相対リンクの整合性検証** — 以下のリンク経路がすべて有効 (リンク先ファイルが実在) であること:
   - `coding/SKILL.md` → `references/<lang>-skill.md` (各言語)
   - `coding/SKILL.md` → `../docs-moonbit/SKILL.md` および `../docs-components-build/SKILL.md`
   - `references/<lang>-skill.md` → `references/<lang>-*.md` (各個別トピック)
   - 同様の経路を `test/SKILL.md` についても検証
   - 検証手段: 各 SKILL.md / `<lang>-skill.md` から相対リンクを抽出し、リンク先ファイルが実在することを確認
   - **外部依存スキル参照は対象外**: `<lang>-skill.md` 内の「外部スキル参照」セクションはスキル名のみで Markdown link を張らないため、本検証は適用しない
5. **3 種 marketplace.json 整合性の検証** — 以下を JSON パースで確認:
   - **`.claude-plugin/marketplace.json`** (編集 base): `plugins[]` から `moonbit` / `components-build` エントリが削除され、`{"name": "totto2727-coding", "source": "./plugins/totto2727-coding"}` が含まれる
   - **`.cursor-plugin/marketplace.json`**: base と同一スキーマで totto2727-coding を含み、moonbit / components-build を含まない (= sync 後の状態)
   - **`.agents/plugins/marketplace.json`**: Codex フォーマット (`source: {path: "./plugins/totto2727-coding", source: "local"}` + `policy` + `category`) で totto2727-coding を含み、旧プラグインを含まない
6. **ハードコードパス参照の不残検証** — リポジトリ全体に対して以下を `grep -r` で検索し、新パスへ更新済みもしくは参照ゼロであること:
   - `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` (旧 `.agents/skills/` パス文字列を含むもの)
   - `plugins/moonbit/` / `plugins/components-build/` (旧プラグインパス)
   - `.agents/skills/effect-` / `.agents/skills/totto2727-fp` (旧スキル直リンク)
   - 検索対象: CLAUDE.md (project / user), 他 SKILL.md, `agents/*.md`, `.claude/` 配下
7. **生成スクリプトの型チェック通過検証** — 以下のコマンドが exit 0 で成功すること:
   - `deno check plugins/totto2727-coding/.script/generate-docs-moonbit.ts`
   - `deno check plugins/totto2727-coding/.script/generate-docs-components-build.ts`
   - (スクリプトの実行による外部 fetch 結果の再現性は本サイクル外)
8. **3 種 plugin manifest 一致の検証** — `plugins/totto2727-coding/` 配下に以下が存在し、内容 (name / description / version / author) が完全一致:
   - `.claude-plugin/plugin.json` (編集 base)
   - `.codex-plugin/plugin.json` (sync 派生)
   - `.cursor-plugin/plugin.json` (sync 派生)
9. **`.claude/settings.json` の `enabledPlugins` 整合性** — JSON パースで以下を確認:
   - `"moonbit@totto2727"` および `"components-build@totto2727"` エントリが削除されている
   - `"totto2727-coding@totto2727": true` が追加されている
   - `"dev-workflow@totto2727"` および `"totto2727@totto2727"` は維持されている
10. **`vp check` 通過検証** (= CI と同等の formatting / lint / type check):
    - `vp check` が exit 0 で成功すること (oxfmt formatting issue 不存在)

## Constraints

### Technical constraints

- **plugin.json スキーマ**: Claude Agent SDK の plugin spec に準拠する必要がある (既存 `plugins/moonbit/.claude-plugin/plugin.json` 等を参考にする)
- **生成スクリプトの実行環境**: Deno で動作する前提を維持 (`generate-docs-moonbit.ts` / `generate-docs-components-build.ts` は Deno script)
- **slash command の参照パス**: `.claude/skills/update-*.md` 内のスクリプト起動パスは新プラグイン構造に合わせて書き換える必要がある
- **docs-moonbit/references/ ライセンスヘッダ**: 既存ファイルに含まれる MoonBit 公式ドキュメントのライセンスヘッダは保持する (再生成時にも維持)

### Organizational constraints

- **auto mode で進行**: ユーザーは auto mode を選択中。routine な決定は Specialist の判断で進めて良い
- **本サイクル内で完結**: dotfiles 側 (`totto2727-dotfiles/agents`) リポジトリには触らない (Out of scope 参照)

### Normative constraints

- **既存コーディング規約の中身は変更しない**: Effect 流儀 / `@totto2727/fp` の使い方等の規約内容は移行のみ
- **`coding/SKILL.md` / `test/SKILL.md` の 300 行 hard cap**: ユーザー明示指示。SKILL.md は言語非依存の基本方針 + 言語/外部仕様の目次に限定し、詳細は references/ に委ねる
- **責務分離**: 「コーディング規約 (手書き)」と「外部仕様リファレンス (自動生成)」は別スキルとして並列に置き、混合しない
- **スキル命名規則** (ユーザー追加指示で確定):
  - **トップレベルスキル** (新規 / 手書き): `coding`, `test` (規則なし)
  - **外部ドキュメントクローンスキル** (自動生成): `docs-*` プレフィックス (`docs-moonbit`, `docs-components-build`)
- **既存スキル構造の維持**: ディレクトリ内部構造 (`SKILL.md` + `references/*.md`) は維持し、変更はリネーム + frontmatter `name:` 更新 + 内部リンクの相対パス調整のみ (ユーザー指示「現在のスキル構造を維持」)

## Related links

- ユーザーの初期要求 (verbatim、本ドキュメント Background 参照)
- ユーザー追加指示 (verbatim、本ドキュメント Scope.3 参照): 「components-build-docs プラグインのスキルも coding プラグインに移動 / moonbit-docs と同様に現在のスキル構造を維持」
- 既存プラグイン:
  - `plugins/moonbit/` (削除対象)
  - `plugins/components-build/` (削除対象)
  - `plugins/dev-workflow/` (本ワークフロー本体、移行対象外)
  - `plugins/totto2727/` (汎用スキル群、本サイクルでは触らない)
- 既存 `.agents/skills/`:
  - `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` (移行対象、実ディレクトリ)
  - `remix` (本サイクル対象外、`5e92483` で別経路から昇格)
  - `vite-plus` (本サイクル対象外、symlink → node_modules)
- ルート 3 種 marketplace ファイル (更新対象、編集 base = `.claude-plugin/marketplace.json`):
  - `.claude-plugin/marketplace.json` (Claude 用)
  - `.cursor-plugin/marketplace.json` (Cursor 用、sync 派生)
  - `.agents/plugins/marketplace.json` (Codex 用、sync 派生)
- `.claude/settings.json` の `enabledPlugins` (更新対象)
- `c-plugin dev marketplace sync` 実装: `js/app/c-plugin/src/service/marketplace-sync.ts:62-82` (toClaudeCursorFormat / toCodexFormat の変換ロジック)
- `dev-workflow` Skills:
  - `plugins/dev-workflow/skills/share-artifacts/templates/intent-spec.md` (本ドキュメントのテンプレート)
  - `plugins/dev-workflow/skills/share-artifacts/references/intent-spec.md` (書き方ガイド)

## Open questions

Step 2 Research で確定した結果と、Step 3 Architect 以降に申し送る項目に分けて整理。

### Step 2 で確定済み

1. ~~**dotfiles 側 registry 更新の要否**~~ → **不要** (`plugin-discovery-mechanism.md` で確定: Claude Code は `extraKnownMarketplaces` 経由で本リポジトリ marketplace.json を直読み)
2. ~~**`.agents/skills-lock.json` における新プラグインの登録形式**~~ → **対象消滅** (`5e92483` で本リポジトリから削除済、Cursor/Codex 配布は `.agents/plugins/marketplace.json` + `c-plugin dev marketplace sync` に移行)

### Step 3 (Architect) 以降に申し送り

3. **`coding/SKILL.md` における外部仕様リファレンス (`docs-moonbit` / `docs-components-build`) の配置形式**:
   - 「言語インデックス」と並列に「外部仕様リファレンス」セクションを設けるか、各言語インデックス (`mbt-skill.md` 等) から間接参照させるか
   - Step 3 (Architect) の判断に委ねる (Intent Spec では「`coding/SKILL.md` の目次から参照する」とのみ記載)
4. ~~**`test/SKILL.md` における TypeScript セクションの扱い**~~ → **解消** (ユーザー追加指示で `vite-plus` を `test/references/ts-skill.md` に外部スキル参照として含めることが確定。プレースホルダではなく実コンテンツ含むため `ts-skill.md` を新規作成)
5. **CLAUDE.md (project / user) への新プラグイン情報の追記要否**:
   - `cross-references.md` で確認済: 既存 CLAUDE.md は旧スキル / 旧プラグインを一切名指ししておらず Claude Code の auto-discovery で十分 (= **追記不要**)
   - ただし `dev-workflow` 本体内の旧スキル名 placeholder 言及 12 箇所 (cross-references UQ-1) を本サイクルで書き換えるか別サイクル送りかは Step 3 で判断
6. **移行先 references/ ファイルの frontmatter 扱い** (cross-references UQ-3, skill-content-migration から):
   - 各 `references/<name>.md` ファイルで frontmatter `name:` フィールドを保持するか削除するか (`shared-artifacts/references/` 慣習に倣い削除推奨)
   - Step 3 (Architect) で確定
7. **`import.meta.dirname` null guard の追加** (scripts-and-slash-commands U-2):
   - 既存スクリプト 2 本は現状でも `deno check` が TS2345 で失敗するため、SC-7 達成のため移行と同時に null guard 追加が必須
   - 本サイクル内で吸収する (Step 5 Task Plan に明記)
