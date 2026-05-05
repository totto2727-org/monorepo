# Research Note: skill-content-migration

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Topic:** skill-content-migration <!-- 移行対象スキル本文と内部リンク (相対パス再計算) -->
- **Researcher:** researcher (single instance)
- **Created at:** 2026-05-04
- **Scope:** 移行対象 8 スキル本文に含まれる Markdown link を全件抽出し、移行先からの新相対パスを計算。リンク切れ・stale 参照・frontmatter description 内の他スキル名参照の有無を確定する。

## Subject of investigation

Intent Spec の **Success criterion #4 (3 階層相対リンク整合性)** および Scope #3 の「移行はリネームと相対パス調整のみ」を成立させるために、Implementer (Step 6) が機械的に消化できる **「書き換え必要リンクの全件一覧」** を確定させる。

調査対象ファイル (8 件):

1. `.agents/skills/effect-layer/SKILL.md`
2. `.agents/skills/effect-runtime/SKILL.md`
3. `.agents/skills/effect-hono/SKILL.md`
4. `.agents/skills/totto2727-fp/SKILL.md`
5. `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md`
6. `plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md`
7. `plugins/moonbit/skills/moonbit-docs/SKILL.md`
8. `plugins/components-build/skills/components-build-docs/SKILL.md`

加えて `plugins/moonbit/skills/moonbit-docs/references/*.md` (25 ファイル、構造維持移動) について、内部相対リンクが追従するかをサンプリング検証 (代表 3 ファイル: `language-fundamentals-built-in-data-structures.md` / `language-methods.md` / `toolchain-index.md`)。

## Findings

### F-1. 抽出対象 8 スキル本文に存在する Markdown link 数 (種別別)

| 移行元ファイル                                                           | ソースコード | 兄弟スキル | 詳細リファレンス | 外部 URL |           合計 |
| ------------------------------------------------------------------------ | -----------: | ---------: | ---------------: | -------: | -------------: |
| `.agents/skills/effect-layer/SKILL.md`                                   |            3 |          2 |                0 |        0 |              5 |
| `.agents/skills/effect-runtime/SKILL.md`                                 |            2 |          2 |                0 |        0 |              4 |
| `.agents/skills/effect-hono/SKILL.md`                                    |            7 |          2 |                0 |        0 |              9 |
| `.agents/skills/totto2727-fp/SKILL.md`                                   |            0 |          0 |                0 |        1 |              1 |
| `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md`                   |            0 |          1 |                1 |        0 |              2 |
| `plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md` |            0 |          0 |                0 |        0 |              0 |
| `plugins/moonbit/skills/moonbit-docs/SKILL.md`                           |            0 |          1 |               25 |        0 | 26 (+ 1 stale) |
| `plugins/components-build/skills/components-build-docs/SKILL.md`         |            0 |          0 |                0 |        1 |              1 |

合計 48 リンク (うち書き換え必要: 後述 R-1〜R-7 に分類)。

### F-2. リンク切れ (stale 参照) の検出

- **F-2-a (移行前から既存):** `plugins/moonbit/skills/moonbit-docs/SKILL.md:263`
  - `Check out [build system tutorial](../toolchain/moon/tutorial.md) for detail.`
  - リンク先 `plugins/moonbit/skills/toolchain/moon/tutorial.md` は **現状リポジトリに存在しない** (`gfind plugins/moonbit -name tutorial.md` で 0 件)。
  - 構造維持移動後は `plugins/totto2727-coding/skills/moonbit-docs/SKILL.md` から `../toolchain/moon/tutorial.md` を参照することになるが、`plugins/totto2727-coding/skills/toolchain/` も作成されないため **リンク切れは温存される**。
- **F-2-b (`moonbit-docs/references/*.md` 内、サンプリング):** references 内の本文には `methods.md`, `packages.md`, `derive.md`, `../toolchain/vscode/index.md`, `moon/tutorial.md`, `wasm/index.md` 等の **同一 references/ ディレクトリには存在しないファイル** へのリンクが多数 (例: `language-methods.md:94` の `(packages.md#trait-implementations)` は references/ 内に `packages.md` が存在せず、`language-packages.md` が正しい)。
  - これらは **MoonBit 公式ドキュメントから自動生成 (`process-moonbit-docs.ts`)** された名残であり、現状でも壊れている。
  - 構造維持移動 (references/ ごと丸ごと移動) では相対パスは追従するため **新規にリンク切れは発生しない** (= 既存の壊れ方を温存)。
  - Intent Spec 「規約内容そのものの大幅な改訂は Out of scope」 (line 136) より、本サイクルでは **修正しない**。
- **F-2-c (新規発生): なし** (Implementer が新パス計算を正しく行えば、新たなリンク切れは発生しない)。

### F-3. frontmatter `description:` 内の他スキル名参照

`description:` 中の `Do NOT use for: ... (use X skill).` 句に含まれる **他スキル名** は、リネームがあれば追従が必要。

| ファイル                         | description 内で参照されている旧スキル名 | リネーム後の新スキル名                              | 書き換え要否            |
| -------------------------------- | ---------------------------------------- | --------------------------------------------------- | ----------------------- |
| `effect-layer/SKILL.md`          | `effect-runtime`, `effect-hono`          | (移行後はスキルではなく references/ ファイルになる) | **要検討** (R-3 で扱う) |
| `effect-runtime/SKILL.md`        | `effect-layer`, `effect-hono`            | 同上                                                | **要検討**              |
| `effect-hono/SKILL.md`           | `effect-layer`, `effect-runtime`         | 同上                                                | **要検討**              |
| `moonbit-bestpractice/SKILL.md`  | (なし)                                   | —                                                   | 不要                    |
| `moonbit-docs/SKILL.md`          | (なし)                                   | —                                                   | 不要                    |
| `components-build-docs/SKILL.md` | (なし)                                   | —                                                   | 不要                    |
| `totto2727-fp/SKILL.md`          | (なし)                                   | —                                                   | 不要                    |

**設計上の判断ポイント:**

- 移行後、`effect-*` は **独立した SKILL ではなく `coding/references/ts-effect-*.md` (中間/詳細リファレンス)** に降格する (Intent Spec Scope #2 / #3)。
- 詳細リファレンスは Claude が自動 description マッチングする対象ではなく、上位 SKILL.md (`coding/SKILL.md` または `coding/references/ts-skill.md`) からたどられる位置づけ。
- したがって `description:` フィールド自体を保持するか、あるいは「単なる H1 + 本文」に簡素化するかは Step 3 (Architect) で確定すべき (本観点では未決定として Open Question 化)。

### F-4. frontmatter `name:` フィールドのリネーム要否

| ファイル                                          | 現 `name:`              | 新位置                                   | name フィールド扱い                               |
| ------------------------------------------------- | ----------------------- | ---------------------------------------- | ------------------------------------------------- |
| `effect-layer/SKILL.md`                           | `effect-layer`          | `coding/references/ts-effect-layer.md`   | references ファイルは frontmatter 不要 (削除候補) |
| `effect-runtime/SKILL.md`                         | `effect-runtime`        | `coding/references/ts-effect-runtime.md` | 同上                                              |
| `effect-hono/SKILL.md`                            | `effect-hono`           | `coding/references/ts-effect-hono.md`    | 同上                                              |
| `totto2727-fp/SKILL.md`                           | `totto2727-fp`          | `coding/references/ts-totto2727-fp.md`   | 同上                                              |
| `moonbit-bestpractice/SKILL.md`                   | `moonbit-bestpractice`  | `coding/references/mbt-bestpractice.md`  | 同上                                              |
| `moonbit-bestpractice/references/moonbit-test.md` | (frontmatter なし)      | `test/references/mbt-bestpractice.md`    | そもそも frontmatter なし                         |
| `moonbit-docs/SKILL.md`                           | `moonbit-docs`          | `moonbit-docs/SKILL.md`                  | **保持** (SKILL のまま)                           |
| `components-build-docs/SKILL.md`                  | `components-build-docs` | `components-build-docs/SKILL.md`         | **保持** (SKILL のまま)                           |

**設計上の判断ポイント:** references/_.md に frontmatter を残すか除去するかは既存 dev-workflow / shared-artifacts の references の慣習に従う。`plugins/dev-workflow/skills/share-artifacts/references/_.md` を確認したところ frontmatter は存在しない (`# Reference: How to write ...` で開始)。したがって移行時に **frontmatter ブロックは削除** が自然。Step 3 で確定。

### F-5. 書き換え必要リンク全件一覧 (Implementer 向け)

#### R-1. `effect-layer/SKILL.md` → `coding/references/ts-effect-layer.md`

| 旧リンク (line)        | 旧パス                                                      | 新パス                                                               | 種別                  |
| ---------------------- | ----------------------------------------------------------- | -------------------------------------------------------------------- | --------------------- |
| L16 `[effect-runtime]` | `../effect-runtime/SKILL.md`                                | `./ts-effect-runtime.md`                                             | 兄弟リファレンス      |
| L16 `[effect-hono]`    | `../effect-hono/SKILL.md`                                   | `./ts-effect-hono.md`                                                | 兄弟リファレンス      |
| L74 `[env.ts]`         | `../../js/app/saas-example/src/feature/env.ts`              | `../../../../../js/app/saas-example/src/feature/env.ts`              | ソース (※ 5 階層上り) |
| L75 `[kysely.ts]`      | `../../js/app/saas-example/src/feature/db/kysely.ts`        | `../../../../../js/app/saas-example/src/feature/db/kysely.ts`        | ソース                |
| L76 `[better-auth.ts]` | `../../js/app/saas-example/src/feature/auth/better-auth.ts` | `../../../../../js/app/saas-example/src/feature/auth/better-auth.ts` | ソース                |

#### R-2. `effect-runtime/SKILL.md` → `coding/references/ts-effect-runtime.md`

| 旧リンク (line)           | 旧パス                                                    | 新パス                                                             | 種別             |
| ------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------ | ---------------- |
| L15 `[effect-layer]`      | `../effect-layer/SKILL.md`                                | `./ts-effect-layer.md`                                             | 兄弟リファレンス |
| L15 `[effect-hono]`       | `../effect-hono/SKILL.md`                                 | `./ts-effect-hono.md`                                              | 兄弟リファレンス |
| L43 `[runtime/server.ts]` | `../../js/app/saas-example/src/feature/runtime/server.ts` | `../../../../../js/app/saas-example/src/feature/runtime/server.ts` | ソース           |
| L44 `[runtime/hono.ts]`   | `../../js/app/saas-example/src/feature/runtime/hono.ts`   | `../../../../../js/app/saas-example/src/feature/runtime/hono.ts`   | ソース           |

#### R-3. `effect-hono/SKILL.md` → `coding/references/ts-effect-hono.md`

| 旧リンク (line)            | 旧パス                                                            | 新パス                                                                     | 種別             |
| -------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------- | ---------------- |
| L16 `[effect-layer]`       | `../effect-layer/SKILL.md`                                        | `./ts-effect-layer.md`                                                     | 兄弟リファレンス |
| L16 `[effect-runtime]`     | `../effect-runtime/SKILL.md`                                      | `./ts-effect-runtime.md`                                                   | 兄弟リファレンス |
| L61 `[auth/middleware.ts]` | `../../js/app/saas-example/src/feature/auth/middleware.ts`        | `../../../../../js/app/saas-example/src/feature/auth/middleware.ts`        | ソース           |
| L87 `[auth/app.ts]`        | `../../js/app/saas-example/src/feature/auth/app.ts`               | `../../../../../js/app/saas-example/src/feature/auth/app.ts`               | ソース           |
| L88 `[entry.hono.ts]`      | `../../js/app/saas-example/src/entry.hono.ts`                     | `../../../../../js/app/saas-example/src/entry.hono.ts`                     | ソース           |
| L106 `[http/error.ts]`     | `../../js/app/saas-example/src/feature/http/error.ts`             | `../../../../../js/app/saas-example/src/feature/http/error.ts`             | ソース           |
| L117 `[entry.hono.ts]`     | `../../js/app/saas-example/src/entry.hono.ts`                     | `../../../../../js/app/saas-example/src/entry.hono.ts`                     | ソース           |
| L118 `[context.ts]`        | `../../js/app/saas-example/src/feature/share/lib/hono/context.ts` | `../../../../../js/app/saas-example/src/feature/share/lib/hono/context.ts` | ソース           |
| L118 `[factory.ts]`        | `../../js/app/saas-example/src/feature/share/lib/hono/factory.ts` | `../../../../../js/app/saas-example/src/feature/share/lib/hono/factory.ts` | ソース           |

#### R-4. `totto2727-fp/SKILL.md` → `coding/references/ts-totto2727-fp.md`

| 旧リンク (line)         | 旧パス                                                                            | 新パス     | 種別     |
| ----------------------- | --------------------------------------------------------------------------------- | ---------- | -------- |
| L62 `[Effect AI Guide]` | `https://raw.githubusercontent.com/Effect-TS/effect-smol/refs/heads/main/LLMS.md` | (変更なし) | 外部 URL |

書き換え不要 (リンク 1 件のみ、外部 URL)。

#### R-5. `moonbit-bestpractice/SKILL.md` → `coding/references/mbt-bestpractice.md`

| 旧リンク (line)                    | 旧パス                         | 新パス                                      | 種別                                          |
| ---------------------------------- | ------------------------------ | ------------------------------------------- | --------------------------------------------- |
| L12 `[moonbit-docs]`               | `../moonbit-docs/SKILL.md`     | `../../moonbit-docs/SKILL.md`               | 別スキル (SKILL のまま保持)                   |
| L311 `[MoonBit Testing Standards]` | `./references/moonbit-test.md` | `../../test/references/mbt-bestpractice.md` | **テスト規約への参照 (テストスキル側へ移動)** |

**注意 (L311):** 旧構造では「コーディング規約 SKILL の references/ 配下のテスト規約」という入れ子だったが、新構造では「`test/` スキルが独立」したため、`coding/references/mbt-bestpractice.md` から `test/references/mbt-bestpractice.md` へ **2 階層 (`../../test/references/`) を跨ぐ参照** に再編される。意味論的には「コーディング規約からテスト規約への See also」になる。Step 3 で本リンクを残すか / `coding/SKILL.md` 経由に再構成するかを確定すべき。

#### R-6. `moonbit-bestpractice/references/moonbit-test.md` → `test/references/mbt-bestpractice.md`

リンクなし。書き換え不要。

#### R-7. `moonbit-docs/SKILL.md` → `moonbit-docs/SKILL.md` (構造維持、相対深さ同一)

| 旧リンク (line)                                      | 旧パス                             | 新パス                                     | 種別                     |
| ---------------------------------------------------- | ---------------------------------- | ------------------------------------------ | ------------------------ |
| L17 `[moonbit-bestpractice]`                         | `../moonbit-bestpractice/SKILL.md` | `../coding/references/mbt-bestpractice.md` | **別スキルへ降格**       |
| L263 `[build system tutorial]`                       | `../toolchain/moon/tutorial.md`    | (リンク切れ温存、F-2-a)                    | stale (修正は別サイクル) |
| L288–L313 `[language-*.md]`, `[toolchain-*.md]` × 25 | `./references/<file>.md`           | (変更なし)                                 | 内部 (構造維持)          |

**注意 (L17):** 旧構造では「兄弟スキル `moonbit-bestpractice/`」だったが、新構造では `coding/references/mbt-bestpractice.md` (詳細リファレンス) に降格する。`moonbit-docs/SKILL.md` は `coding/` の隣の独立スキルなので、`../coding/references/mbt-bestpractice.md` で参照する形になる。Step 3 で「Related Skills」表記を残すか「Related References」等に変更するかも検討対象。

#### R-8. `components-build-docs/SKILL.md` → `components-build-docs/SKILL.md` (構造維持)

| 旧リンク (line)                                         | 旧パス                                  | 新パス                                                                 | 種別                  |
| ------------------------------------------------------- | --------------------------------------- | ---------------------------------------------------------------------- | --------------------- |
| L18 `<!-- Generated from ... sitemap.xml -->`           | (コメント、リンクではない)              | —                                                                      | —                     |
| L20 `<!-- Run .script/generate-skill.ts to update -->`  | (コメント)                              | 新コメント: `Run .script/generate-components-build-skill.ts to update` | 補助コメント (要更新) |
| L43 `[vercel-composition-patterns]`                     | `https://raw.githubusercontent.com/...` | (変更なし)                                                             | 外部 URL              |
| L52 `curl https://www.components.build/llms.mdx/{slug}` | (URL、リンクではない)                   | —                                                                      | —                     |

**注意:** L20 のコメントは厳密には Markdown link ではないが、Intent Spec Scope #3 で `generate-skill.ts → generate-components-build-skill.ts` にリネームすることが明記されているので **本文中のスクリプトファイル名参照も同時に追従が必要**。

### F-6. moonbit-docs/references/\*.md (25 ファイル) の構造維持移動

サンプリング (`language-fundamentals-built-in-data-structures.md`, `language-methods.md`, `toolchain-index.md`) より:

- 内部相対リンク (例: `methods.md`, `packages.md#trait-implementations`, `../toolchain/vscode/index.md`) は **どれも references/ ディレクトリ単位で完結 or 既存リンク切れ** であり、`plugins/moonbit/skills/moonbit-docs/references/` から `plugins/totto2727-coding/skills/moonbit-docs/references/` への構造維持移動では **新たな書き換えは不要**。
- 外部 URL (`https://mooncakes.io/...`) は当然変更不要。
- ライセンスヘッダコメント (各ファイル冒頭の `<!-- ... -->` ブロック) は **保持必須** (Intent Spec Constraints "moonbit-docs/references/ ライセンスヘッダ" 参照)。

### F-7. 兄弟スキル間 cross-reference (Related skills) の再編

旧構造の `effect-*/SKILL.md` 冒頭にある以下のパターンは、新構造で別物に変わる:

```markdown
Related skills: [effect-runtime](../effect-runtime/SKILL.md), [effect-hono](../effect-hono/SKILL.md)
```

→ 新構造では references/ 内の **同階層の兄弟ファイル** (`./ts-effect-runtime.md` 等) への参照になる。

意味論的にも「Related skills」(別 SKILL 群) ではなく「Related references」(同一 SKILL 内の関連トピック) と表現するほうが正確。**Step 3 (Architect) で「見出し名と相対パス両方」を一括して再編する判断が必要**。

## Sources

### 抽出に用いたコマンド

```bash
ggrep -nE '\[[^]]+\]\([^)]+\)' \
  .agents/skills/effect-layer/SKILL.md \
  .agents/skills/effect-runtime/SKILL.md \
  .agents/skills/effect-hono/SKILL.md \
  .agents/skills/totto2727-fp/SKILL.md \
  plugins/moonbit/skills/moonbit-bestpractice/SKILL.md \
  plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md \
  plugins/moonbit/skills/moonbit-docs/SKILL.md \
  plugins/components-build/skills/components-build-docs/SKILL.md
```

### 個別根拠

- `effect-layer/SKILL.md:16,74-76` — Related skills + Layer.succeed/sync/effect の TS リンク
- `effect-runtime/SKILL.md:15,43-44` — Related skills + Reference Implementation
- `effect-hono/SKILL.md:16,61,87-88,106,117-118` — Related skills + 各セクションの Examples
- `totto2727-fp/SKILL.md:62` — Effect AI Guide (外部 URL)
- `moonbit-bestpractice/SKILL.md:12,311` — moonbit-docs 参照 + Testing Standards 参照
- `moonbit-docs/SKILL.md:17,263,288-313` — moonbit-bestpractice 参照 + build system tutorial (stale) + 25 references リスト
- `components-build-docs/SKILL.md:18-20,43,52` — 自動生成コメント + vercel-composition-patterns + curl 例
- `moonbit-docs/references/language-fundamentals-built-in-data-structures.md:146,188` 等 — references/ 内本文の相対リンクパターンサンプリング
- `moonbit-docs/references/language-methods.md:94,364,581` — `packages.md` / `derive.md` 等の同階層参照
- `moonbit-docs/references/toolchain-index.md:9-43` — `moon/index.md`, `wasm/index.md` 等の同階層子ディレクトリ参照 (現状リンク切れ)

### リンク先実体存在確認 (TypeScript ソース)

```bash
for f in js/app/saas-example/src/feature/env.ts ...; do [ -e "$f" ] && echo OK; done
```

→ 全 11 ファイル存在確認済 (R-1〜R-3 のソースリンク全件有効)。

### 新相対パス計算 (Python `os.path.relpath` で実測)

```python
os.path.relpath('plugins/totto2727-coding/skills/coding/references', 'js/app/saas-example/src/feature/env.ts')
# → '../../../../../js/app/saas-example/src/feature/env.ts'
```

→ **5 階層上り** が正しい (旧 `.agents/skills/effect-layer/` からの 2 階層上りと比較して大幅増加)。Implementer は機械的な置換で対応可能。

### Intent Spec 該当箇所

- `intent-spec.md:170-175` (Success criterion #4: 3 階層相対リンク整合性検証)
- `intent-spec.md:93-106` (Scope #3: 移行マッピング表)
- `intent-spec.md:136-138` (Out of scope: 規約内容そのものの大幅な改訂は対象外 → F-2-a/F-2-b の stale 温存判断の根拠)
- `intent-spec.md:208` (Constraints: 既存スキル名は新プラグイン内でも維持 → F-4 の moonbit-docs / components-build-docs の name 保持判断の根拠)

## Implications for design

### I-1. Implementer (Step 6) のタスク粒度の指針

R-1 〜 R-8 は **「ファイル単位 × リンク種別単位」で機械的に消化可能** な変換である。Step 5 (Task Decomposition) では:

- **タスク 1 件 = 移行元ファイル 1 件のリネーム + リンク書き換え** とする粒度が妥当 (合計 8 タスク + moonbit-docs/references/ の構造維持移動 1 タスク + components-build-docs スクリプト名参照更新 1 タスク = 約 10 タスク)。
- ソースコードへの相対パス書き換え (`../../js/...` → `../../../../../js/...`) は **5 階層に統一** されるため、`sed` 級の機械置換で対応可能。
- 兄弟リファレンス書き換え (`../effect-runtime/SKILL.md` → `./ts-effect-runtime.md`) は **コンテキスト依存の意味再編** を伴うため、Implementer による手動編集が必要 (R-1 / R-2 / R-3 / R-7 が該当)。

### I-2. Step 3 (Architect) で確定すべき設計判断 5 件

1. **(F-3) references/\*.md における frontmatter `description:` の扱い**
   - 詳細リファレンスから description ブロックを削除するか保持するか。`shared-artifacts/references/` の慣習に倣えば削除が自然。
2. **(F-3 / F-7) 兄弟参照セクションの見出し名再編**
   - 旧 `Related skills:` ヘッダを `Related references:` 等に変更するか、それとも本文内のリンクのみ変更してヘッダは残すか。
3. **(R-5 L311) `coding/references/mbt-bestpractice.md` から `test/references/mbt-bestpractice.md` への参照を残すか**
   - 残す場合、相対リンク `../../test/references/mbt-bestpractice.md` (2 階層を跨ぐ) で本当に良いか。あるいは `coding/SKILL.md` 経由のナビゲーションに切り替えるか。
4. **(R-7 L17) `moonbit-docs/SKILL.md` の Related Skills 表記**
   - 旧「兄弟 SKILL `moonbit-bestpractice`」が、新構造で「別 SKILL `coding` の references」に降格する事実をどう記述するか。リンク先のみ書き換えるか、文言全体を「コーディング規約は `coding/` スキル参照」と再構成するか。
5. **(F-2-a) `moonbit-docs/SKILL.md:263` の stale link `../toolchain/moon/tutorial.md`**
   - 移行時にコメントアウト or 削除するか、それともそのまま温存するか。Intent Spec の Out of scope 解釈次第 (現状の解釈は「規約内容そのもの」=「コーディング規約の中身」を指すため、リンク切れ修正は許容範囲とも読めるが、保守的には「修正しない」が妥当)。

### I-3. Success criterion #4 の検証手順への含意

Validation Step 8 でリンク整合性を確認する際、以下の手順が機械実行可能:

```bash
# 1. 各 SKILL.md / references/<lang>-skill.md からリンク抽出
ggrep -nEho '\[[^]]+\]\(([^)]+)\)' plugins/totto2727-coding/skills/**/*.md

# 2. 各リンクの相対パスを resolve して実在確認
# (外部 URL は除外、内部 .md / .ts のみ対象)
```

ただし F-2-a / F-2-b で温存される **既存リンク切れも検出される** ため、Validation Report では「移行に起因する新規リンク切れ = 0」と「既存リンク切れ (移行前から存在) = N 件 (一覧)」を分けて報告する必要がある。

### I-4. ハードコード文字列の置換漏れリスク

Success criterion #6 (ハードコードパス参照の不残検証) と関連:

- `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` という **スキル名文字列** が、本観点の対象 8 ファイル外 (例: 他のプロジェクト CLAUDE.md, 他の dev-workflow 成果物) にも残存している可能性。
- 本観点では 8 ファイル内のリンクのみ扱うため、**リポジトリ全体の grep 検証は別観点 (cross-references) の責務** (実際 `research/cross-references-raw-*.txt` が既に存在する)。
- Implementer は本ノート R-1〜R-8 を消化後、cross-references 観点の Research Note と統合した「全リポジトリ置換チェックリスト」をレビューする必要がある。

### I-5. 自動生成スクリプトの出力先パス書き換え (本観点の隣接領域)

本観点の主対象ではないが、F-5 R-8 で触れた `components-build-docs/SKILL.md` 本文の **「Run .script/generate-skill.ts to update」コメント** は:

- スクリプトの実ファイル名が `generate-skill.ts` → `generate-components-build-skill.ts` にリネームされる (Intent Spec Scope #3) ため、本文も同期更新が必要。
- 同様に `moonbit-docs/SKILL.md` には現状スクリプト名への直接言及はないが、`process-moonbit-docs.ts` の出力先パスを書き換えると **moonbit-docs/SKILL.md ヘッダコメント (`<!-- Derived from MoonBit documentation by moonbitlang -->` 等) は不変** で良い (出力先パスの記述は含まれていない)。

## Remaining unknowns

### U-1. `moonbit-docs/references/*.md` 25 ファイル全件のリンク切れ網羅調査

サンプリング 3 ファイルでは多数の既存リンク切れを確認したが、25 ファイル全件のリンク網羅調査は本サイクルの主目的 (= 新パス計算) からはずれるため未実施。Validation Step 8 で `find + grep` ベースの網羅検出を行えば、移行起因 vs 既存起因の切り分けが可能。本サイクルでの追加調査は不要 (Out of scope: 規約内容の改訂)。

### U-2. references/\*.md の H1 見出し変更要否

旧 `effect-layer/SKILL.md` の H1 は `# Effect Layer Definition Patterns` だが、新ファイル名は `ts-effect-layer.md`。H1 を新ファイル名に整合させるか (例: `# TypeScript: Effect Layer Definition Patterns`)、それとも元のまま維持するかは Step 3 (Architect) の判断対象。本観点ではリンク再計算に影響しないため未確定。

### U-3. effect-\* 兄弟ファイル間の循環参照テストの要否

R-1 / R-2 / R-3 で `./ts-effect-{layer,runtime,hono}.md` 同士が相互参照する。3 ファイル間の循環リンクが Validation で問題視されないか (= リンク整合性チェッカーが循環を許容するか) は未確認。ただし Markdown は循環参照を許容するため通常問題なし。Step 8 で確認。

### U-4. components-build-docs の `metadata:` ブロック保持要否

`components-build-docs/SKILL.md:13-15` の `metadata: author: totto2727 / version: 0.1.0` は新位置 (構造維持) で保持されるが、新プラグイン全体としてバージョン管理戦略をどうするか (= `0.1.0` をそのまま引き継ぐか、新プラグインの `plugin.json` 側に集約するか) は別観点 (plugin.json schema 観点) の責務。本観点では「保持で問題なし」とのみ記録。
