# Research Note: scripts-and-slash-commands

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Topic:** scripts-and-slash-commands
- **Researcher:** researcher (parallel instance, scripts & slash command perspective)
- **Created at:** 2026-05-04
- **Scope:** 自動生成スクリプト 2 本 (`process-moonbit-docs.ts` / `generate-skill.ts`) と slash command 2 本 (`update-moonbit-docs.md` / `update-components-build-docs.md`) の移行に伴う書き換え範囲の特定、および Intent Spec Success Criterion #7 (`deno check` 通過) のベースライン確認。

## Subject of investigation

Intent Spec の以下を実現するための前提調査。

- **Scope.3 移行表 (行 102, 105)**: スクリプト 2 本の出力先パス書き換え + `generate-skill.ts` を `generate-components-build-skill.ts` にリネーム。
- **Scope.3 移行表 (行 103, 106)**: slash command 2 本の `deno run` 起動コマンド書き換え。
- **Constraints (行 195)**: slash command 内のスクリプト起動パスは新プラグイン構造に合わせて書き換え必須。
- **Success criterion #7 (行 184-187)**: 移行後の `plugins/totto2727-coding/.script/process-moonbit-docs.ts` および `generate-components-build-skill.ts` に対する `deno check` が exit 0 で成功すること。

本 Note はこの 4 ファイルにスコープを限定する。`coding/SKILL.md` 設計、`.agents/skills-lock.json` 更新、CLAUDE.md 追記要否などは別 Research Note (cross-references 系) の責務とする。

## Findings

### F-1. 既存 `process-moonbit-docs.ts` のハードコード箇所

`plugins/moonbit/.script/process-moonbit-docs.ts` の以下が新パスへの移行対象:

- **L8 (コメント内のコマンド例)**: 起動コマンド例として `.script/process-moonbit-docs.ts` を記載。プラグイン内相対パスのため文字列としては変更不要だが、新プラグイン側でも一貫しているか確認要。
- **L20-22 (出力先解決ロジック)**:
  ```ts
  const scriptDir = import.meta.dirname
  const projectRoot = join(scriptDir, '..')
  const outputDir = join(projectRoot, 'skills', 'moonbit-docs')
  ```
  `projectRoot` は `plugins/<plugin-name>/` を指す。`outputDir` の `'moonbit-docs'` 部分はスキル名で、Intent Spec Scope.3 移行表 (行 101) で「構造ごと維持」とあるため**変更不要**。新プラグインでも `plugins/totto2727-coding/skills/moonbit-docs/` に出力される (相対解決ロジックがそのまま動く)。
- **L130-132 (Related Skills ブロック)**:

  ```ts
  const relatedSkillsBlock = `## Related Skills

  ```

- [moonbit-bestpractice](../moonbit-bestpractice/SKILL.md) — MoonBit coding standards and best practices. Use when writing, reviewing, or refactoring MoonBit code.`
  ```
  これは生成される `moonbit-docs/SKILL.md` に埋め込まれる文字列で、現状 `../moonbit-bestpractice/SKILL.md` を参照している。Intent Spec Scope.3 で `moonbit-bestpractice` は `plugins/totto2727-coding/skills/coding/references/mbt-bestpractice.md` (および `test/references/mbt-bestpractice.md`) に再配置されるため、**書き換え必須**。
  ```

### F-2. 既存 `process-moonbit-docs.ts` の `deno check` ベースライン

```bash
$ deno check plugins/moonbit/.script/process-moonbit-docs.ts
TS2345 [ERROR]: Argument of type 'string | undefined' is not assignable to parameter of type 'string | URL'.
  Type 'undefined' is not assignable to type 'string | URL'.
const projectRoot = join(scriptDir, '..')
                         ~~~~~~~~~
    at file:///.../plugins/moonbit/.script/process-moonbit-docs.ts:21:26
error: Type checking failed.
```

Deno 2.6.10 / TypeScript 5.9.2 環境では `import.meta.dirname` が `string | undefined` 型 (Deno LSP/CLI の最新挙動。Node.js compat だがファイル URL でない場合 undefined になり得る) として推論されるため、**現状でも `deno check` を通過しない**。Intent Spec SC #7 を新パスで満たすには、移行と同時に当該箇所の null guard を追加する必要がある。

### F-3. 既存 `generate-skill.ts` のハードコード箇所

`plugins/components-build/.script/generate-skill.ts`:

- **L6 (コメント内 Usage)**: `.script/generate-skill.ts` を記載。リネーム後は `.script/generate-components-build-skill.ts` に更新する必要あり (コメントも追従が望ましい)。
- **L12-14 (出力先解決)**:
  ```ts
  const scriptDir = import.meta.dirname
  const projectRoot = join(scriptDir, '..')
  const outputDir = join(projectRoot, 'skills', 'components-build-docs')
  ```
  `process-moonbit-docs.ts` と同じパターン。`'components-build-docs'` 部分は Intent Spec で構造維持のため変更不要。
- **L131-132 (生成 SKILL.md 内コメント)**:
  ```ts
  <!-- Generated from https://www.components.build/sitemap.xml -->
  <!-- Run .script/generate-skill.ts to update -->
  ```
  生成コードに直書きされており、**リネーム後は `.script/generate-components-build-skill.ts` に書き換え必須**。

### F-4. 既存 `generate-skill.ts` の `deno check` ベースライン

```bash
$ deno check plugins/components-build/.script/generate-skill.ts
TS2345 [ERROR]: Argument of type 'string | undefined' is not assignable to parameter of type 'string | URL'.
const projectRoot = join(scriptDir, '..')
                         ~~~~~~~~~
    at file:///.../plugins/components-build/.script/generate-skill.ts:13:26
error: Type checking failed.
```

同じく `import.meta.dirname` の `string | undefined` 起因で**現状未通過**。F-2 と同じ修正 (null guard) が必要。

### F-5. slash command `update-moonbit-docs.md`

- **L11 (Overview 文)**: `skills/moonbit-docs/` を参照。プラグイン相対パスのため、Intent Spec で構造維持される `moonbit-docs/` 部分は**変更不要**。ただし旧プラグイン文脈で書かれたパスである旨の意識は必要 (検索で誤検出されない確認は可)。
- **L20-24 (実行コマンド)**:
  ```bash
  deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts "<language-url>" "<toolchain-url>"
  ```
  スクリプトファイル名が同名で移行されるため、**変更不要**。プラグイン root 相対パス (`.script/...`) の解決は新プラグインでも同一。
- **L26 (Verify output 文)**: `skills/moonbit-docs/` を参照。同上、変更不要。
- **frontmatter `name: update-moonbit-docs`**: Intent Spec Scope.3 でスキル名衝突回避が指示されていない (現プラグインに同名 slash command は無い)。**そのまま維持**で問題なし。

### F-6. slash command `update-components-build-docs.md`

- **L11 (Overview)**: `skills/components-build-docs/` を参照。同上 (変更不要)。
- **L16-18 (実行コマンド)**:
  ```bash
  deno run --allow-net --allow-read --allow-write .script/generate-skill.ts
  ```
  Intent Spec Scope.3 でスクリプト名が `.script/generate-components-build-skill.ts` にリネームされるため、**書き換え必須**。
- **L20 (Verify output)**: `skills/components-build-docs/SKILL.md` を参照。変更不要。
- **frontmatter `name: update-components-build-docs`**: 維持で問題なし。

### F-7. リネーム妥当性 (`generate-skill.ts` → `generate-components-build-skill.ts`)

新プラグイン `plugins/totto2727-coding/.script/` には以下 2 ファイルが並ぶ:

- `process-moonbit-docs.ts` (役割名がファイル名から自明)
- `generate-skill.ts` (リネームしない場合 — 何のスキルを生成するのか不明瞭)

リネームは**妥当**と判断。理由:

1. 並列で見たとき `generate-skill.ts` だけ責務が不明瞭になる (他のスクリプトが追加された際の混乱の元)。
2. Intent Spec Scope.3 で明示的に新名 `generate-components-build-skill.ts` が指定されており、ユーザー意図と整合。
3. リネームに伴うコード本文の影響範囲は L6 コメントと L132 の生成 SKILL.md 内コメント (F-3 参照) のみで限定的。
4. `import.meta.dirname` 等の動的解決ロジックは**ファイル名に依存しない**ため、リネームによる動作影響なし。

## Sources

- スクリプト本体: `plugins/moonbit/.script/process-moonbit-docs.ts:L1-L156`
- スクリプト本体: `plugins/components-build/.script/generate-skill.ts:L1-L196`
- slash command: `plugins/moonbit/.claude/skills/update-moonbit-docs.md:L1-L26`
- slash command: `plugins/components-build/.claude/skills/update-components-build-docs.md:L1-L20`
- 生成済み SKILL.md (Related Skills 確認): `plugins/moonbit/skills/moonbit-docs/SKILL.md:L15-L17`
- moonbit-docs references 規模: 26 ファイル (`gls plugins/moonbit/skills/moonbit-docs/references/ | gwc -l`)
- Intent Spec: `docs/workflow/2026-05-04-totto2727-coding-plugin/intent-spec.md`
  - Scope.3 移行表 (行 93-106)
  - Constraints 行 195 (slash command の参照パス)
  - Success criterion #7 (行 184-187): `deno check` 通過要件
- Deno バージョン: `deno 2.6.10 (stable, release, aarch64-apple-darwin) / typescript 5.9.2`
- リポジトリ root に `deno.json` / `deno.jsonc` は**存在しない** (`gfind . -maxdepth 3 -name 'deno.json*'` が空)。各スクリプトは標準 Deno CLI 設定で type-check される。

## Implications for design

### I-1. Implementer タスク分解への入力 (推奨粒度)

スクリプト & slash command の移行を以下 4 タスクに分解することを推奨 (Step 5 planner への申し送り):

| Task                 | 内容                                                                                                                                                                                                                                                                       | 規模  | 依存                 |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | -------------------- |
| T-S1                 | `process-moonbit-docs.ts` を新パスにコピー + L130-132 の Related Skills リンク書き換え (`../moonbit-bestpractice/SKILL.md` → `../coding/references/mbt-bestpractice.md`、ただし配置先は Step 3 architect の判断に委ねる) + L20 に `import.meta.dirname` の null guard 追加 | 30 分 | なし                 |
| T-S2                 | `generate-skill.ts` を `generate-components-build-skill.ts` として新パスにコピー + L6 / L132 のコメント内ファイル名更新 + L13 に `import.meta.dirname` の null guard 追加                                                                                                  | 30 分 | なし                 |
| T-C1                 | `update-moonbit-docs.md` を新パスにコピー (本文書き換え不要)                                                                                                                                                                                                               | 5 分  | なし                 |
| T-C2                 | `update-components-build-docs.md` を新パスにコピー + L17 のスクリプト名を `generate-components-build-skill.ts` に書き換え                                                                                                                                                  | 10 分 | T-S2 完了後 (検証時) |
| T-V (validator 領域) | 新パスの 2 スクリプトに `deno check` を実行し exit 0 を確認                                                                                                                                                                                                                | —     | T-S1 / T-S2 完了後   |

### I-2. `import.meta.dirname` null guard の具体形 (両スクリプト共通)

```ts
const scriptDir = import.meta.dirname
if (scriptDir === undefined) {
  console.error('import.meta.dirname is not available; run with --allow-read or as a file URL')
  Deno.exit(1)
}
const projectRoot = join(scriptDir, '..')
```

または non-null assertion (`scriptDir!`) は型安全性を損なうため非推奨。Deno script は基本 file URL から実行されるため `undefined` になるのは異常系で、明示 exit が望ましい。

### I-3. Related Skills リンク書き換えの結論

`moonbit-docs/SKILL.md` 内の `Related Skills` 行 (`../moonbit-bestpractice/SKILL.md`) は **`process-moonbit-docs.ts:L130-132` の `relatedSkillsBlock` 変数で動的生成**されており、実体ファイルへの直書きではない。

**結論**: スクリプト側の修正のみで完結する。実体ファイル `moonbit-docs/SKILL.md` の文字列を git 上で直接書き換える二重作業は不要 (ただし、移行直後に再生成する前は古いリンク `../moonbit-bestpractice/SKILL.md` が新プラグイン内に残る点に注意)。新プラグイン側の `moonbit-docs/SKILL.md` をスクリプト無しでまず正しい状態にしたい場合は、コピー時に当該 3 行 (L17 周辺) も書き換える追加タスクを設けるべき。

→ **Step 3 architect への問い**: 新プラグインに `moonbit-docs/SKILL.md` を「コピー後に再生成しない」運用を許容するなら、コピー時の文字列書き換えタスクが必要。再生成前提なら不要。

### I-4. slash command 書き換えの限定性

slash command 2 本のうち、本文書き換えが必要なのは `update-components-build-docs.md` の L17 のみ (1 行)。`update-moonbit-docs.md` は単純コピーで動作する。これは Intent Spec Scope.3 の表記 「(パス書き換え)」に対する具体化として、planner / implementer の見積りに使える。

### I-5. SC #7 達成のクリティカルパス

Intent Spec SC #7 (`deno check` 通過) は**移行作業に伴う追加修正なしには達成不可能** (F-2 / F-4 参照、現状ベースラインで失敗)。Implementer は移行と同時に I-2 の null guard を必ず入れる必要がある。これを「移行作業の副作用」として暗黙に含めるのではなく、Task Plan に明示すべき。

## Remaining unknowns

### U-1. moonbit-docs/SKILL.md コピー時の Related Skills リンク先

I-3 の通り、新プラグイン内 `moonbit-docs/SKILL.md` をコピー直後の状態でも整合させたい場合、リンク先を `../coding/references/mbt-bestpractice.md` (もしくは `../test/references/mbt-bestpractice.md`、または両方) のどちらにすべきかは Step 3 architect の判断 (Intent Spec Scope.3 で `moonbit-bestpractice` は coding/test 両方の references に分割移行されるため、文脈的には `coding/references/mbt-bestpractice.md` が妥当に見えるが、確定は architect の責務)。

### U-2. `import.meta.dirname` の null guard が「リネーム + パス書き換え」と独立スコープか

Intent Spec Scope.3 の移行表は「出力先パス書き換え」「パス書き換え」と書かれているのみで、null guard 追加 (型安全性向上) を含むとは明示されていない。SC #7 を満たす最低限の修正として含めて良いか、別 issue として切り出すべきかは Main の判断 (推奨は同一サイクル内で吸収。理由: SC #7 が同サイクルの成功基準であり、満たすには修正必須)。

### U-3. slash command の frontmatter `name:` 衝突

Step 1 で plugin / skill 構造の他観点を別 researcher が調査中であれば、新プラグイン内に既に同名 slash command がないかを cross-check 推奨。本 researcher の確認範囲では `plugins/totto2727-coding/` は未作成のため衝突なし。
