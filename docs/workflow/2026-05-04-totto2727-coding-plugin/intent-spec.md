# Intent Spec: Consolidate coding/test/docs skills into `totto2727-coding` plugin

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Author:** intent-analyst (dev-workflow Step 1)
- **Created at:** 2026-05-04
- **Last updated:** 2026-05-04

## Background

現在、totto2727 のコーディング規約・ベストプラクティス・外部仕様リファレンスに関する Skill / Plugin 資産が以下の通り分散しており、参照ポイントが複数存在することでメンテナンス負荷と探索コストが上がっている。

- `plugins/moonbit/` プラグイン
  - `skills/moonbit-bestpractice/` — MoonBit 言語のベストプラクティス (手書き、コーディング規約) + `references/moonbit-test.md` (テスト規約)
  - `skills/moonbit-docs/` — MoonBit 言語リファレンス 25+ ファイル (`.script/process-moonbit-docs.ts` で MoonBit 公式から自動生成、ライセンスヘッダ付き)
  - `.script/process-moonbit-docs.ts` — Deno 製生成スクリプト
  - `.claude/skills/update-moonbit-docs.md` — 上記を起動する slash command
- `plugins/components-build/` プラグイン
  - `skills/components-build-docs/SKILL.md` — Vercel components-build 仕様リファレンス
  - `.script/generate-skill.ts` — 同スキルの自動生成スクリプト
  - `.claude/skills/update-components-build-docs.md` — slash command
- `.agents/skills/` (プロジェクト直置き、プラグイン外)
  - `effect-layer/SKILL.md` — Effect Layer/Service 定義パターン (TypeScript)
  - `effect-runtime/SKILL.md` — Effect Layer 合成 + ManagedRuntime (TypeScript)
  - `effect-hono/SKILL.md` — Effect + Hono 統合 (TypeScript)
  - `totto2727-fp/SKILL.md` — `@totto2727/fp` パッケージ使用ガイド (TypeScript)
- `.agents/skills-lock.json` — 上記のうち `moonbit-bestpractice` / `moonbit-docs` / `components-build-docs` を `source: totto2727-dotfiles/agents` (外部 dotfiles リポジトリ) 経由で有効化

これらは性質ごとに 2 種類に大別できる:
1. **コーディング規約・テスト規約** (手書き、totto2727 固有の流儀) — `moonbit-bestpractice` + effect-* + totto2727-fp
2. **外部仕様リファレンス** (自動生成、第三者仕様の取り込み) — `moonbit-docs` + `components-build-docs`

これらが「totto2727 のコーディング流儀全般」という単一の関心事に属するにもかかわらず、複数のプラグイン / `.agents/skills/` 直置きという複数のオーナーシップに分散している状態が、Skill 活用時の「どこを参照すべきか」を不明瞭にしている。

## Purpose

totto2727 固有のコーディング規約 (言語非依存方針 + 言語別ベストプラクティス) とテスト規約、および totto2727 が日常的に参照する外部仕様リファレンス (MoonBit 言語仕様 / components-build 仕様) を、単一の `plugins/totto2727-coding` プラグイン配下に集約・再構成し、Skill 探索の単一エントリポイント (`coding/SKILL.md` および `test/SKILL.md`) を確立する。

## Scope

### 1. 新規プラグイン `plugins/totto2727-coding/` の作成

以下の構造で新規プラグインを作成する:

```
plugins/totto2727-coding/
├── .claude-plugin/plugin.json
├── .script/
│   ├── process-moonbit-docs.ts
│   └── generate-components-build-skill.ts
├── .claude/
│   └── skills/
│       ├── update-moonbit-docs.md
│       └── update-components-build-docs.md
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
    ├── moonbit-docs/
    │   ├── SKILL.md
    │   └── references/
    │       └── (25+ 個の言語リファレンスファイル、構造維持)
    └── components-build-docs/
        └── SKILL.md
```

### 2. `coding/SKILL.md` および `test/SKILL.md` の新規作成

3 階層構造のエントリポイントとして:

- `SKILL.md` (300 行以内、hard cap)
  - 言語非依存の基本方針 (型安全性 / 副作用局所化 / 命名意図性 / テスト可能性 等の普遍原則)
  - 言語インデックス (`ts-skill.md` / `mbt-skill.md` 等への誘導)
  - 外部仕様リファレンス (`moonbit-docs` / `components-build-docs`) への誘導 (`coding/SKILL.md` のみ)
- `references/<lang>-skill.md` (中間目次)
  - その言語の個別トピック (`<lang>-*.md`) への索引と、各トピックを参照する状況の説明
- `references/<lang>-*.md` (詳細)
  - 既存スキルの内容を移植 (リネームのみ、内容は基本維持)

### 3. 既存スキル / プラグインの移行 + 削除

| 移行元 | 移行先 |
|---|---|
| `.agents/skills/effect-layer/SKILL.md` | `plugins/totto2727-coding/skills/coding/references/ts-effect-layer.md` |
| `.agents/skills/effect-runtime/SKILL.md` | `plugins/totto2727-coding/skills/coding/references/ts-effect-runtime.md` |
| `.agents/skills/effect-hono/SKILL.md` | `plugins/totto2727-coding/skills/coding/references/ts-effect-hono.md` |
| `.agents/skills/totto2727-fp/SKILL.md` | `plugins/totto2727-coding/skills/coding/references/ts-totto2727-fp.md` |
| `plugins/moonbit/skills/moonbit-bestpractice/SKILL.md` | `plugins/totto2727-coding/skills/coding/references/mbt-bestpractice.md` |
| `plugins/moonbit/skills/moonbit-bestpractice/references/moonbit-test.md` | `plugins/totto2727-coding/skills/test/references/mbt-bestpractice.md` |
| `plugins/moonbit/skills/moonbit-docs/` (構造ごと) | `plugins/totto2727-coding/skills/moonbit-docs/` |
| `plugins/moonbit/.script/process-moonbit-docs.ts` | `plugins/totto2727-coding/.script/process-moonbit-docs.ts` (出力先パス書き換え) |
| `plugins/moonbit/.claude/skills/update-moonbit-docs.md` | `plugins/totto2727-coding/.claude/skills/update-moonbit-docs.md` (パス書き換え) |
| `plugins/components-build/skills/components-build-docs/` (構造ごと) | `plugins/totto2727-coding/skills/components-build-docs/` |
| `plugins/components-build/.script/generate-skill.ts` | `plugins/totto2727-coding/.script/generate-components-build-skill.ts` (出力先パス書き換え) |
| `plugins/components-build/.claude/skills/update-components-build-docs.md` | `plugins/totto2727-coding/.claude/skills/update-components-build-docs.md` (パス書き換え) |

移行完了後、以下を完全削除する:
- `plugins/moonbit/` (ディレクトリごと)
- `plugins/components-build/` (ディレクトリごと)
- `.agents/skills/effect-layer/`
- `.agents/skills/effect-runtime/`
- `.agents/skills/effect-hono/`
- `.agents/skills/totto2727-fp/`

### 4. `.agents/skills-lock.json` の更新

本リポジトリの `.agents/skills-lock.json` を以下方針で更新:
- `enabledSkills` から旧スキル名 (`moonbit-bestpractice`, `moonbit-docs`, `components-build-docs`) を削除
- `totto2727-coding` プラグインを新規登録 (`enabledSkills: ["coding", "test", "moonbit-docs", "components-build-docs"]`)
- 配置パスの整合は Step 2 (Research) / Step 3 (Architect) で確定する (現行の `repositories[].path` 構造を踏襲する想定)

### 5. 命名規約

言語固有 references/ ファイルには以下の prefix を使用:
- `ts-` — TypeScript 専用 (Effect / totto2727-fp 等)
- `mbt-` — MoonBit
- `js-` — JavaScript 共通 (将来の拡張用に予約。本サイクルでは新規ファイル作成なし)

## Out of scope

- **`source: totto2727-dotfiles/agents` (外部 dotfiles リポジトリ) 側の registry / lock 更新**
  - 本サイクルでは本リポジトリの `.agents/skills-lock.json` のみ更新する
  - dotfiles 側で `totto2727-coding` プラグインの登録が必要かどうかは Step 2 (Research) で要否判断する Open Question 扱い (本サイクルのスコープ外)
- **既存 SKILL.md / references/ 本文の規約内容そのものの大幅な改訂**
  - 移行はリネームと相対パス調整のみ。規約の中身 (例: Effect Layer 定義のベストプラクティス) は別サイクルで扱う
- **新規言語 (Go, Rust 等) の skill / references 追加**
  - `ts-` / `mbt-` 以外の言語は本サイクルでは作成しない
- **`coding/SKILL.md` / `test/SKILL.md` への大規模な新規方針 (Google style guide 風サマリ等) の書き起こし**
  - 「言語非依存の基本方針 + 言語の目次」を 300 行以内で記述するに留める
- **テスト規約の TypeScript 版 (`test/references/ts-*.md`)**
  - 現状 TS テスト規約に該当する移行元スキルがないため、本サイクルでは作成しない (将来追加余地のみ確保)
- **CLAUDE.md (project / user) への新プラグインのドキュメント追記**
  - 必要性は Step 2 / Step 3 で判断 (現状 CLAUDE.md には effect-* スキル等への直接参照は確認されていない)

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
   - `plugins/totto2727-coding/skills/moonbit-docs/SKILL.md`
   - `plugins/totto2727-coding/skills/components-build-docs/SKILL.md`
   - `plugins/totto2727-coding/skills/coding/references/{ts-skill,ts-effect-layer,ts-effect-runtime,ts-effect-hono,ts-totto2727-fp,mbt-skill,mbt-bestpractice}.md`
   - `plugins/totto2727-coding/skills/test/references/{mbt-skill,mbt-bestpractice}.md`
   - `plugins/totto2727-coding/.script/process-moonbit-docs.ts`
   - `plugins/totto2727-coding/.script/generate-components-build-skill.ts`
   - `plugins/totto2727-coding/.claude/skills/update-moonbit-docs.md`
   - `plugins/totto2727-coding/.claude/skills/update-components-build-docs.md`
3. **SKILL.md 行数上限の検証** — `wc -l plugins/totto2727-coding/skills/coding/SKILL.md` と `wc -l plugins/totto2727-coding/skills/test/SKILL.md` が**それぞれ 300 行以下**であること
4. **3 階層相対リンクの整合性検証** — 以下のリンク経路がすべて有効 (リンク先ファイルが実在) であること:
   - `coding/SKILL.md` → `references/<lang>-skill.md` (各言語)
   - `coding/SKILL.md` → `../moonbit-docs/SKILL.md` および `../components-build-docs/SKILL.md`
   - `references/<lang>-skill.md` → `references/<lang>-*.md` (各個別トピック)
   - 同様の経路を `test/SKILL.md` についても検証
   - 検証手段: 各 SKILL.md / `<lang>-skill.md` から相対リンクを抽出し、リンク先ファイルが実在することを確認
5. **`.agents/skills-lock.json` 更新の検証** — JSON をパースして以下を確認:
   - 旧スキル名 (`moonbit-bestpractice`, `moonbit-docs`, `components-build-docs`) を含む `enabledSkills` エントリが**旧プラグイン (moonbit / components-build) 文脈で**存在しない
   - `totto2727-coding` プラグインがエントリとして登録され、`enabledSkills` に新スキル名 (`coding`, `test`, `moonbit-docs`, `components-build-docs`) が含まれる
6. **ハードコードパス参照の不残検証** — リポジトリ全体に対して以下を `grep -r` で検索し、新パスへ更新済みもしくは参照ゼロであること:
   - `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` (旧 `.agents/skills/` パス文字列を含むもの)
   - `plugins/moonbit/` / `plugins/components-build/` (旧プラグインパス)
   - `.agents/skills/effect-` / `.agents/skills/totto2727-fp` (旧スキル直リンク)
   - 検索対象: CLAUDE.md (project / user), 他 SKILL.md, `agents/*.md`, `.claude/` 配下
7. **生成スクリプトの型チェック通過検証** — 以下のコマンドが exit 0 で成功すること:
   - `deno check plugins/totto2727-coding/.script/process-moonbit-docs.ts`
   - `deno check plugins/totto2727-coding/.script/generate-components-build-skill.ts`
   - (スクリプトの実行による外部 fetch 結果の再現性は本サイクル外)

## Constraints

### Technical constraints

- **plugin.json スキーマ**: Claude Agent SDK の plugin spec に準拠する必要がある (既存 `plugins/moonbit/.claude-plugin/plugin.json` 等を参考にする)
- **生成スクリプトの実行環境**: Deno で動作する前提を維持 (`process-moonbit-docs.ts` / `generate-components-build-skill.ts` は Deno script)
- **slash command の参照パス**: `.claude/skills/update-*.md` 内のスクリプト起動パスは新プラグイン構造に合わせて書き換える必要がある
- **moonbit-docs/references/ ライセンスヘッダ**: 既存ファイルに含まれる MoonBit 公式ドキュメントのライセンスヘッダは保持する (再生成時にも維持)

### Organizational constraints

- **auto mode で進行**: ユーザーは auto mode を選択中。routine な決定は Specialist の判断で進めて良い
- **本サイクル内で完結**: dotfiles 側 (`totto2727-dotfiles/agents`) リポジトリには触らない (Out of scope 参照)

### Normative constraints

- **既存コーディング規約の中身は変更しない**: Effect 流儀 / `@totto2727/fp` の使い方等の規約内容は移行のみ
- **`coding/SKILL.md` / `test/SKILL.md` の 300 行 hard cap**: ユーザー明示指示。SKILL.md は言語非依存の基本方針 + 言語/外部仕様の目次に限定し、詳細は references/ に委ねる
- **責務分離**: 「コーディング規約 (手書き)」と「外部仕様リファレンス (自動生成)」は別スキルとして並列に置き、混合しない
- **既存 plugin / skill 命名との衝突回避**: `moonbit-docs` / `components-build-docs` 等の既存スキル名は新プラグイン内でも維持 (ユーザー明示指示「現在のスキル構造を維持」)

## Related links

- ユーザーの初期要求 (verbatim、本ドキュメント Background 参照)
- ユーザー追加指示 (verbatim、本ドキュメント Scope.3 参照): 「components-build-docs プラグインのスキルも coding プラグインに移動 / moonbit-docs と同様に現在のスキル構造を維持」
- 既存プラグイン:
  - `plugins/moonbit/` (削除対象)
  - `plugins/components-build/` (削除対象)
  - `plugins/dev-workflow/` (本ワークフロー本体、移行対象外)
  - `plugins/totto2727/` (汎用スキル群、本サイクルでは触らない)
- 既存 `.agents/skills/`:
  - `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` (移行対象)
- `.agents/skills-lock.json` (更新対象)
- `dev-workflow` Skills:
  - `plugins/dev-workflow/skills/share-artifacts/templates/intent-spec.md` (本ドキュメントのテンプレート)
  - `plugins/dev-workflow/skills/share-artifacts/references/intent-spec.md` (書き方ガイド)

## Open questions

以下を Step 2 (Research) のリサーチ対象として申し送る。

1. **dotfiles 側 registry 更新の要否**:
   - 現状 `.agents/skills-lock.json` は `source: totto2727-dotfiles/agents` を指している
   - 本リポジトリ内の `plugins/totto2727-coding/` を有効化するために、dotfiles 側で何か登録が必要か (= dotfiles 側の registry が plugin 一覧の master か、ローカル plugin パスを直接登録できるか) を Research で確定する
   - 本サイクルでは dotfiles 側更新は非スコープ。Research 結果次第で別サイクルへ送る
2. **`.agents/skills-lock.json` における新プラグインの登録形式**:
   - 既存 `repositories[].plugins[]` に追加するか、別の `repositories[]` エントリ (本リポジトリをローカル参照) として登録するか、または `skillDirs[]` を活用するか
   - Step 2 で skills-lock.json の schema / loader 実装を確認して確定する
3. **`coding/SKILL.md` における外部仕様リファレンス (`moonbit-docs` / `components-build-docs`) の配置形式**:
   - 「言語インデックス」と並列に「外部仕様リファレンス」セクションを設けるか、各言語インデックス (`mbt-skill.md` 等) から間接参照させるか
   - Step 3 (Architect) の判断に委ねる (Intent Spec では「`coding/SKILL.md` の目次から参照する」とのみ記載)
4. **`test/SKILL.md` における TypeScript セクションの扱い**:
   - 移行元の TS テスト規約スキルが存在しないため、`test/references/ts-skill.md` をプレースホルダとして作成するか、当面 `test/SKILL.md` の言語インデックスから TS セクション自体を省略するか
   - Step 3 (Architect) で判断
5. **CLAUDE.md (project / user) への新プラグイン情報の追記要否**:
   - 現状 effect-* / 旧 moonbit プラグインへの直接参照は CLAUDE.md には確認されていないが、新プラグインの存在を CLAUDE.md に記載すべきか (= 開発時に Claude が新プラグインを認知するためのエントリポイント整備の必要性) を Research で判断
