# c-plugin: Local Source Support

## TL;DR

> **Quick Summary**: c-plugin に `--local <path>` フラグを追加し、`~/...` または `./...` のローカルパスを指定して `.cache` を介さずに **直接シンボリックリンク** で skill をインストールできるようにする。既存の GitHub フローは無変更。
>
> **Deliverables**:
>
> - `src/lib/paths.ts` の path 検証 / 解決 / `findAgentsRoot()` 追加
> - 対応 plugin フォーマット検出ヘルパー
> - `lock-file.ts` schema を `sourceType: 'github' | 'local'` の discriminated union に拡張
> - `cache.ts` `ensureRepo` に local 分岐（clone skip、`.cache` 不使用、直接 path 返却）
> - `cli/skill/add.ts` に `--local <path>` フラグ + 厳格 validation
> - `cli/skill/sync.ts` / `update.ts` / `remove.ts` に `sourceType` 分岐（git 操作スキップ、re-link、cache 削除スキップ）
> - 各タスクは TDD（RED-GREEN-REFACTOR）+ Agent QA シナリオ付き
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves (Wave 1 = 4 tasks, Wave 2 = 4 tasks, Wave 3 = 1 task)
> **Critical Path**: T1 → T3 → T4 → T5 → T9 → F1-F4

---

## Context

### Original Request

c-plugin スキルを拡張して、任意のファイルパス（`.claude-plugin` / `.cursor-plugin` / Codex 等のプラグインフォーマットを含むディレクトリ）を指定し、そこへのシンボリックリンクを貼る形で skill をインストールできるようにする。現状は GitHub のみ対応で、すべて `.cache` 経由でリンクされている。ローカル指定では `.cache` を介さず、実装箇所へ直接シンボリックリンクを貼る。

### Interview Summary

**Key Discussions**:

- Plugin formats: `.claude-plugin` 限定ではなく、c-plugin が discover で認識する**全フォーマット**を対象
- ユーザーが指定するパスは「プラグインフォーマットディレクトリを**含む**ディレクトリ」（= リポジトリルート相当）
- CLI UX: **明示フラグ** `--local <path>`（auto-detect は不採用）
- 受け入れるパス形式: `~/...` または `./...` のみ。**絶対パスは拒否**
- `./` の基準: **`.agents/` ディレクトリの親**（プロジェクトルート相当）
- lock-file には入力形式のまま保存（解決後の絶対パスは保存しない）
- sync / update on local: **Re-link**（壊れたリンクの修復にもなる）
- インストール時バリデーション: **Strict**（パス存在 + 対応フォーマット存在）
- `sourceType` 拡張: `Schema.Literal('github', 'local')` の **discriminated union**
- `commitHash` は github 側のみ保持、local 側は持たない

**Research Findings**:

- Test framework: `vite-plus/test`（Vitest ラッパー）、`vi` for mocks、`.test.ts` 形式
- `sync.ts` / `update.ts` は現在 `sourceType` 区別なしで全 repo に対し `Git.pull` / `Git.checkout` / `Git.revParseHead` を実行
- `Git.checkInstalled` も無条件で呼ばれている → local-only 運用では git 必須にすべきでない
- `Cache.removeRepo` は `<agentsDir>/.cache/<source>` を削除する設計のため、local では破壊的になる可能性
- `getGitHubCloneUrl` は github 固有、local では呼んではいけない
- `symlink.ts` の `createSkillLink` は target path を受け取るだけ → **local でも変更不要**
- `marketplace-sync.ts` は marketplace 形式パース層で sourceType に直接依存しない → 影響軽微

### Metis Review

**Identified Gaps** (addressed in plan):

- `sync.ts` / `update.ts` の sourceType 無差別分岐 → 全タスクで明示的に分岐を入れる
- `Git.checkInstalled` 呼び出し位置 → local-only でスキップできる構造に
- `Cache.removeRepo` 破壊性 → remove タスクで local 分岐
- 隠れたエッジケース（symlink ループ、`..`、symlink パス、trailing slash、重複インストール）→ validation タスクで対処
- 既存テストパターン（`vite-plus/test` + `vi` mock）→ 全タスクで踏襲

---

## Work Objectives

### Core Objective

c-plugin の skill インストール機能を、GitHub クローン経由に加えて**ローカルパス直接リンク**でも実行できるよう拡張する。

### Concrete Deliverables

- `src/lib/paths.ts` 拡張: `isAllowedLocalPathSpec()`, `resolveLocalPath()`, `findAgentsRoot()`
- 新規 or 既存ファイル拡張: `hasSupportedPluginFormat(path)` 関数
- `src/schema/lock-file.ts` 拡張: `RepositoryEntry` を `sourceType` の discriminated union に
- `src/service/cache.ts` 修正: `ensureRepo` に local 分岐
- `src/cli/skill/add.ts` 修正: `--local <path>` フラグ追加 + 厳格 validation
- `src/cli/skill/sync.ts` 修正: sourceType 分岐、local は re-link only
- `src/cli/skill/update.ts` 修正: sourceType 分岐、local は re-link only
- `src/cli/skill/remove.ts` 修正: sourceType 分岐、local では cache 削除しない
- 各変更箇所に対応する `.test.ts`

### Definition of Done

- [ ] `vp run --filter c-plugin check` がパスする
- [ ] `vp run --filter c-plugin test` が新規 / 既存テスト全てパス
- [ ] `c-plugin skill add --local ./fixtures/sample-plugin` が成功し、`.agents/skills/<name>` がローカルパスへの symlink になっている
- [ ] `c-plugin skill add --local /abs/path` が validation error で失敗する
- [ ] `c-plugin skill add --local ./nonexistent` が path-not-found error で失敗する
- [ ] `c-plugin skill add --local ./empty-dir`（plugin format 無し）が format-missing error で失敗する
- [ ] `c-plugin skill sync` 実行時、local source は git を呼ばず symlink のみ再構築する
- [ ] `c-plugin skill update` 実行時、local source は git を呼ばず symlink のみ再構築する
- [ ] `c-plugin skill remove <name>` 実行時、local source は `.cache` ディレクトリ削除を試みない
- [ ] lock-file 内の local source は `sourceType: 'local'` でかつ入力形式（`~/...` または `./...`）のまま保存されている
- [ ] 既存の GitHub フローは挙動変化なし（既存テストがすべて通過）

### Must Have

- `--local` フラグでのインストール
- `~/...` および `./...` パスのみ受理（絶対パスは拒否）
- `./` の基準は `.agents/` の親
- lock-file には入力形式のまま保存
- 直接シンボリックリンク（`.cache` 不使用）
- 全 CLI コマンドで `sourceType` 分岐
- Strict validation: パス存在 + 対応フォーマット存在
- 各タスクで TDD（RED-GREEN-REFACTOR）
- 既存 GitHub フロー無変更

### Must NOT Have (Guardrails)

- 絶対パス受理（`/abs/path` はエラー）
- auto-detect 方式（フラグ無し引数からの local 推測）
- 既存 GitHub フローの挙動変更
- 新規 marketplace kind の追加
- local source に対する `git` 系操作の実行（pull / checkout / clone）
- local source の `.cache` 配下への書き込み・削除
- local 用に `commitHash` を捏造して入れる
- スコープ外: 他言語向け plugin ホスト（VSCode 拡張等）への対応
- Refactor 便乗（既存 github コードの整理を同 PR に含めない）
- 過剰なバリデーション（symlink ループ等を「念のため」全部検出するのは避け、明確な失敗ケースのみ対応）

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - 全 verification は agent 実行。`/start-work` 後の executor が自動で実施。

### Test Decision

- **Infrastructure exists**: YES
- **Automated tests**: TDD（RED-GREEN-REFACTOR）
- **Framework**: `vite-plus/test`（Vitest ラッパー）
- **Mock library**: `vi` from `vite-plus/test`
- **TDD flow**: 各タスクで失敗テストを先に書き、最小実装でグリーンにし、必要に応じて整理

### QA Policy

全タスクに **agent-executed QA scenarios** を含める。

- **Library/Module 検証**: `Bash` で `bun -e "import('...')"` または直接 vitest 実行
- **CLI 検証**: `interactive_bash`（tmux）で `c-plugin skill add --local ...` を実行、出力 / 終了コード / 生成物を assertion
- **Filesystem 検証**: `Bash` で `ls -la` / `readlink` を実行し、symlink の存在・参照先を確認
- Evidence は `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}` に保存

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation - 4 tasks parallel):
├── T1: paths.ts utilities (isAllowed / resolveLocal / findAgentsRoot) [quick]
├── T2: plugin format detection helper [quick]
├── T3: lock-file schema discriminated union [unspecified-high]
└── T4: (none - small wave)

Wave 2 (Service + CLI - 4 tasks parallel after Wave 1):
├── T4: cache.ts local branch in ensureRepo (depends: T1, T3) [unspecified-high]
├── T5: cli/skill/add.ts --local flag + validation (depends: T1, T2, T3, T4) [unspecified-high]
├── T6: cli/skill/sync.ts sourceType branching (depends: T3, T4) [unspecified-high]
└── T7: cli/skill/update.ts sourceType branching (depends: T3, T4) [unspecified-high]

Wave 3 (Cleanup - 1 task after Wave 2):
└── T8: cli/skill/remove.ts sourceType branching (depends: T3) [quick]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA (unspecified-high)
└── F4: Scope fidelity check (deep)
→ Present results → Get explicit user okay

Critical Path: T1 → T3 → T4 → T5 → F1-F4 → user okay
Parallel Speedup: ~55% faster than sequential
Max Concurrent: 4 (Wave 2)
```

### Dependency Matrix

- **T1**: depends: — | blocks: T4, T5
- **T2**: depends: — | blocks: T5
- **T3**: depends: — | blocks: T4, T5, T6, T7, T8
- **T4**: depends: T1, T3 | blocks: T5, T6, T7
- **T5**: depends: T1, T2, T3, T4 | blocks: F1-F4
- **T6**: depends: T3, T4 | blocks: F1-F4
- **T7**: depends: T3, T4 | blocks: F1-F4
- **T8**: depends: T3 | blocks: F1-F4

### Agent Dispatch Summary

- **Wave 1**: 3 - T1 → `quick`, T2 → `quick`, T3 → `unspecified-high`
- **Wave 2**: 4 - T4 → `unspecified-high`, T5 → `unspecified-high`, T6 → `unspecified-high`, T7 → `unspecified-high`
- **Wave 3**: 1 - T8 → `quick`
- **FINAL**: 4 - F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
      Read this plan end-to-end. For each "Must Have": verify implementation exists（該当 commit / ファイル / コマンド実行で確認）. For each "Must NOT Have": codebase を検索して該当パターンが無いか確認（あれば file:line で reject）。`.sisyphus/evidence/` 配下に evidence file が存在することを確認。deliverables を plan と比較。
      Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
      `vp run --filter c-plugin check` + `vp run --filter c-plugin test` を実行。changed files をレビューし、`as any` / `@ts-ignore` / 空 catch / `console.log` / コメントアウトコード / 未使用 import がないことを確認。AI-slop（過剰コメント、過剰抽象化、generic 名）も検出。
      Output: `Build [PASS/FAIL] | Lint [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
      Clean state から開始。各タスクの QA Scenario を全て実行（CLI 実行 + symlink 検証 + lock-file 内容検証）。クロスタスク結合（add → sync → update → remove の一連フロー）。エッジケース（絶対パス拒否、存在しないパス、フォーマット欠如、重複 install）を一通り。Evidence は `.sisyphus/evidence/final-qa/` に保存。
      Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
      各タスクで「What to do」と実際の diff を 1:1 で照合。spec に無いもの（scope creep）が混入していないか、spec にあるが未実装が無いか。`Must NOT do` 違反、クロスタスク汚染（タスク N が タスク M の領域を触っている）、unaccounted な変更を検出。
      Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **T1**: `feat(c-plugin): add local path utilities to lib/paths` - `src/lib/paths.ts`, `src/lib/paths.test.ts`, `vp run --filter c-plugin test src/lib/paths.test.ts`
- **T2**: `feat(c-plugin): add plugin format detection helper` - `src/lib/plugin-format.ts`, `src/lib/plugin-format.test.ts`, `vp run --filter c-plugin test src/lib/plugin-format.test.ts`
- **T3**: `feat(c-plugin): extend lock-file schema with local sourceType` - `src/schema/lock-file.ts`, `src/schema/lock-file.test.ts` (if exists), `vp run --filter c-plugin check`
- **T4**: `feat(c-plugin): add local branch in cache.ensureRepo` - `src/service/cache.ts`, `src/service/cache.test.ts`, `vp run --filter c-plugin test src/service/cache.test.ts`
- **T5**: `feat(c-plugin): add --local flag to skill add CLI` - `src/cli/skill/add.ts`, `src/cli/skill/add.test.ts` (new), `vp run --filter c-plugin check`
- **T6**: `feat(c-plugin): branch sync command on sourceType` - `src/cli/skill/sync.ts`, `src/service/sync.test.ts`, `vp run --filter c-plugin test src/service/sync.test.ts`
- **T7**: `feat(c-plugin): branch update command on sourceType` - `src/cli/skill/update.ts`, related test, `vp run --filter c-plugin test`
- **T8**: `feat(c-plugin): skip cache cleanup for local source on remove` - `src/cli/skill/remove.ts`, related test, `vp run --filter c-plugin test`

---

## Success Criteria

### Verification Commands

```bash
# Build / lint / type check
vp run --filter c-plugin check
# Expected: exit 0, no errors

# Full test suite
vp run --filter c-plugin test
# Expected: all existing tests + new tests pass

# Local install (happy path)
mkdir -p /tmp/sample-plugin/.claude-plugin
echo '{"name":"sample"}' > /tmp/sample-plugin/.claude-plugin/marketplace.json
cd <project-root-with-.agents>
c-plugin skill add --local ./tmp-sample-plugin  # (after copying / linking fixture)
readlink .agents/skills/sample
# Expected: points to resolved local path, NOT .cache

# Absolute path rejection
c-plugin skill add --local /tmp/sample-plugin
# Expected: exit nonzero, clear error message

# Format missing rejection
mkdir /tmp/empty-dir
c-plugin skill add --local /tmp/empty-dir  # (after copying as ./empty-dir)
# Expected: exit nonzero, "no supported plugin format found"

# sync on local source (no git)
c-plugin skill sync
# Expected: re-links local symlinks without invoking git
```

### Final Checklist

- [ ] All "Must Have" 項目が実装済み
- [ ] All "Must NOT Have" 項目が混入していない
- [ ] 既存テスト全 pass + 新規テスト全 pass
- [ ] 既存 GitHub フローの挙動は無変更（GitHub install / sync / update / remove が引き続き動作）
- [ ] F1-F4 全 APPROVE
- [ ] ユーザーの explicit "okay"
