# Review Report: Readability

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** readability — コードと文書の理解しやすさ・命名の一貫性・コメントの質・ディレクトリ構造の自然さ
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** approved
- **Round count:** 2

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                       | State               | First Round | Resolution commit | Notes                                                                                                                                                                                                                                                                                                          |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `design.md` の Effect Service skeleton コードスニペットが実装と乖離 (`ServiceMap.Service` 表記のまま、実装は全 9 ファイルが `Context.Service` を採用)                                                         | fixed               | 1           | 900b120           | Round 2 確認済: `design.md:106/117/134` のスニペット 3 件 + L934 (CC-6) を `Context.Service` に置換、L146/L212 に Phase 1 deviation note を追加。残存する `ServiceMap.Service` 記述 (L146/L934/L952/L1163/L1218) は SC-6 観測仕様の OR パターンとして意図的に保持され注釈付き。Recommended action と完全一致。 |
| M-2 | Major    | `design.md` 内の `runtime/server.ts` コードスニペット (L156-173) が `Layer.unwrap` の依存解決方法を実装と異なる形で記述 (実装は `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` 形式)                      | fixed               | 1           | 900b120           | Round 2 確認済: `design.md:166-179` のスニペットが実装と同形化 (`envLayer` 変数化 + `dynamicLoggerLayer.pipe(Layer.provide(envLayer))`)、inline コメント (L158/L167-170) と直下の Phase 1 deviation note (L212) で「Env を 2 箇所に provide する」意図が明示。Recommended action と完全一致。                  |
| M-3 | Major    | `js/app/identity-provider/app/routes.ts` (L4-10) と `feed-platform-web/app/routes.ts` (L4-12) の docstring 内容が実態と矛盾。前者は `frames` が空ではないと記述、後者は空である事実を記述。                   | fixed               | 1           | dacf3e4           | Round 2 確認済: `identity-provider/app/routes.ts:13` が `frames = {} as const` に変更、docstring (L4-12) も web 同形化。`feed-platform-web/app/routes.ts` と完全対称。Recommended action「web 側を SoT として IdP を空に合わせる」と完全一致。                                                                 |
| m-1 | Minor    | `js/app/identity-provider/app/ui/document.tsx` に `feed-platform-web/app/ui/document.tsx:10` 相当の説明コメントが欠落 (web 側の "最小 Document コンポーネント..." 行)                                         | pending             | 1           | -                 | 引き継ぎ価値: 後続実装者が IdP 側を読んだとき責務が分かりにくい。`.tsx` :10 と同等行を追加するだけで揃う                                                                                                                                                                                                       |
| m-2 | Minor    | `Document` factory 関数の二重カリー (`export const Document = () => (props) => (...)`) が `hono-remix-v3-cloudflare-example` 由来のため faithful copy だが、読み手に意図不明                                  | pending             | 1           | -                 | [detail](#m-2-minor-detail-document-の二重カリーが何を意味するかコメントがない)                                                                                                                                                                                                                                |
| m-3 | Minor    | `feed-platform-web/.gitignore` は `worker-configuration.d.ts` を ignore する一方、`identity-provider/.gitignore` は ignore しない (差分 + IdP 側で生成 d.ts が一度生成されると tracking 化)                   | fixed               | 1           | dacf3e4           | Round 2 副次解決確認済: `dacf3e4` で `identity-provider/.gitignore:3` に `worker-configuration.d.ts` 追記 (web と同形)。Round 1 [detail](#m-3-minor-detail-3-プロジェクトの-gitignore-不揃い) に説明あり。                                                                                                     |
| m-4 | Minor    | `design.md` の "ADR-XX outline" 節 (L1080-1142) が ADR 起票後も残置。ADR 実体と内容が重複し、今後どちらが SoT か曖昧 (典型的な outline → ADR 転記後の整理タイミング論点)                                      | pending             | 1           | -                 | 引き継ぎ価値: Step 9 Retrospective 候補。ADR 実体がある以上 outline 節は historical reference として明示的に注釈するか削除する                                                                                                                                                                                 |
| m-5 | Minor    | `feed-platform-backend/src/feature/runtime/server.ts:36` 等で `saas-example/src/feature/runtime/server.ts:33-53` を line-range 引用しているが、参照先のリンク化 / 相対パス明示なし                            | pending             | 1           | -                 | 引き継ぎ価値: line range は時間とともにずれる。せめて関数名 (`makeDisposableRuntime`) で識別する形にする方が brittle でない                                                                                                                                                                                    |
| m-6 | Minor    | `js/app/feed-platform-web/app/feature/runtime/server.ts` の `interface DisposableRuntimeInterface` 命名は redundant (TypeScript の慣習では `Interface` サフィックスは推奨されない)                            | pending             | 1           | -                 | 引き継ぎ価値: 3 プロジェクト全部に展開済の命名のため修正コストは中程度。`Disposable<T>` 等の generic 化も検討価値あり                                                                                                                                                                                          |
| m-7 | Minor    | `js/app/feed-platform-web/app/routes.ts` と `js/app/identity-provider/app/routes.ts` で英語/日本語の混在比率が異なる (web 側はほぼ日本語コメント、IdP 側は英語ベース)                                         | pending             | 1           | -                 | 同形プロジェクトとしての一貫性が破れている。Step 9 Retrospective か CC-X 規約追記で吸収する候補                                                                                                                                                                                                                |
| i-1 | Info     | 3 プロジェクトの `feature/{env,greeting,health,runtime/server,runtime/hono}.ts` 5 ファイル群がほぼ完全な同形コピーで存在。将来 `js/package/` への共通化候補                                                   | (consistency check) | 1           | -                 | 引き継ぎ価値: Step 9 Retrospective に明示。design.md S-3 セクション拡張のヒントになる                                                                                                                                                                                                                          |
| i-2 | Info     | Service tag namespace が 3 プロジェクトで規約通り揃っている (`@app/<project-name>/feature/<name>/Service`)                                                                                                    | (consistency check) | 1           | -                 | env.ts/greeting.ts/health.ts × 3 = 9 ファイルすべて確認済                                                                                                                                                                                                                                                      |
| i-3 | Info     | `wrangler.jsonc` の DB binding コメント予約 (IdP) は `vars` 内 (L20-26) と blockのトップレベル (L27-34) に分離されており、ms-02 実装者がコメントを外して値を入れるだけで動く形式                              | (consistency check) | 1           | -                 | observation: 整理されているが、`d1_databases` / `kv_namespaces` の例値 (`...`) は wrangler validation 上有効な UUID 形式ではない (コメントなので通る)。ms-02 に明示的引き継ぎ                                                                                                                                  |
| i-4 | Info     | ADR-01 / ADR-02 の Status / Context / Decision / Consequences / References 5 セクション構造はテンプレ準拠。粒度も後続マイルストーンが「なぜこうなったか」を辿れる粒度                                         | (consistency check) | 1           | -                 | TC-016 / TC-018 観測仕様充足の前提が満たされている (見出し検出件数 = 5 想定)                                                                                                                                                                                                                                   |
| i-5 | Info     | `design.md` / ADR / `intent-spec.md` / `qa-design.md` 全て `design-hint.md` への参照を保持し cross-reference は機能している                                                                                   | (consistency check) | 1           | -                 | `docs/roadmap/feed-platform/design-hint.md` 実体存在を確認 (`ls`)                                                                                                                                                                                                                                              |
| i-6 | Info     | ディレクトリ構造 `feature/{env, greeting, health, runtime/}` は「Hello World 雛形だが将来拡張点が見える」状態。`design.md` S-3 が将来の `event-store/` / `projection/` / `command/` / `query/` への分割を予告 | (consistency check) | 1           | -                 | 拡張点への自然な誘導は OK                                                                                                                                                                                                                                                                                      |

## Detailed sections

### M-1 detail: `ServiceMap.Service` → `Context.Service` deviation が design.md に未反映

**Evidence:**

- `design.md:106` / `:117` / `:134` (Component breakdown - Key types and interfaces) は 3 例とも `ServiceMap.Service<Type>(...)` 表記
- `design.md:926` (CC-6 export 名規約) も `tag: export const Service = ServiceMap.Service<Type>(...)` 表記
- 一方、実装側は **全 9 ファイル (3 プロジェクト × 3 Service)** が `Context.Service` を採用
  - `js/app/feed-platform-backend/src/feature/env.ts:7`: `Context.Service<Type>('@app/feed-platform-backend/feature/env/Service')`
  - `js/app/feed-platform-backend/src/feature/greeting.ts:7`
  - `js/app/feed-platform-backend/src/feature/health.ts:12`
  - `js/app/feed-platform-web/app/feature/env.ts:7` / `greeting.ts:7` / `health.ts:12`
  - `js/app/identity-provider/app/feature/env.ts:7` / `greeting.ts:7` / `health.ts:12`
- TODO.md L34 (T-B notes) に deviation 記録あり: 「design.md の `ServiceMap.Service` は `effect@4.0.0-beta.60` 非対応のため `Context.Service` に置換 (saas-example 整合)」
- ADR-01 (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md:134`) の "Existing impact" セクションに deviation が反映済 (`「**`Context.Service`** に置換」`の記述あり)

**Why this matters for readability:**

- `design.md` を **コード同様にメンテナンスされた SoT (single source of truth)** として読む後続実装者は、Component breakdown のスニペットを真と扱う可能性が高い (典型的な「設計書を見て真似する」運用)
- TODO.md notes と ADR の "Existing impact" にある deviation 記録は、`design.md` を直接読んだ人には届かない (= ADR や TODO まで参照する習慣のない実装者は気づけない)
- design.md の他の節 (`SC-6` mapping table / `qa-design.md` TC-011 と TC-015 の grep パターン) も同じ `ServiceMap.Service` を含むため、deviation が cascade で記述ずれを発生させている

**Recommended action:**

- design.md の Component breakdown スニペット 3 箇所 (L106 / L117 / L134) と CC-6 (L926) を `Context.Service` に修正
- 加えて、design.md L1155 / L1210 / qa-design.md L72 (TC-011) / qa-design.md L38 / intent-spec.md L142 の `ServiceMap.Service` リテラルは「SC-6 観測仕様の grep パターン」(= Effect API のいずれかが使われていればよい) として歴史的に書かれているため、これらは **意図的な OR 記述** として残す判断もありうる (ただし CC-6 / Component breakdown は false-leading なので必ず修正)
- 修正は `design.md` を更新する Step 3 rollback ではなく、deviation 注記 (e.g. "実装上 `Context.Service` を採用、deviation 経緯は ADR-01 Existing impact 参照" を該当スニペットの直下に追加) が読者の認知コスト最小化案

### M-2 detail: `runtime/server.ts` の Layer 合成スニペットも design.md で古い形のまま

**Evidence:**

- `design.md:155-173` (Component breakdown - feature/runtime/server.ts スニペット):

  ```typescript
  const dynamicLoggerLayer = Layer.unwrap(
    Effect.gen(function* () {
      const env = yield* Env.Service
      return Logger.layer([env.ENV === 'production' ? Logger.consoleJson : Logger.consolePretty()])
    }),
  )

  const makeRuntime = (env: Env.Type) =>
    ManagedRuntime.make(
      Health.layer.pipe(
        Layer.provideMerge(Greeting.layer),
        Layer.provideMerge(Env.makeLayer(env)),
        Layer.provide(dynamicLoggerLayer),
      ),
    )
  ```

- 実装側 (3 プロジェクト同形、`js/app/feed-platform-backend/src/feature/runtime/server.ts:18-31`):

  ```typescript
  const makeRuntime = (env: Env.Type) => {
    const envLayer = Env.makeLayer(env)
    return ManagedRuntime.make(
      Health.layer.pipe(
        Layer.provideMerge(Greeting.layer),
        Layer.provideMerge(envLayer),
        Layer.provide(dynamicLoggerLayer.pipe(Layer.provide(envLayer))),
      ),
    )
  }
  ```

- 違い: 実装は `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` で **dynamicLoggerLayer 側に Env を独立 provide** している。design.md の形だと `Layer.provide(dynamicLoggerLayer)` で外側に渡しているのみ
- TODO.md L34 (T-B notes): 「dynamicLoggerLayer の Env 依存解決のために Env Layer を `Layer.provide(envLayer)` で内部に重ねる形式に微調整」
- ADR-01 D-6 (refinement #1) は方針 (`Layer.unwrap` + `Env.Service` 経由判定) を確定しているが、**具体的 Layer 合成形式まで反映する SoT がどこにもない**

**Why this matters for readability:**

- `design.md` のコードスニペットは Component breakdown 節の中核であり、後続 ms-02 / ms-05 等で実装者が Layer 合成の形を真似する際の参照点
- 「実装は design と微妙に違う形 (= Env を 2 箇所に provide する)」という事実は、TODO.md の 1 行で記録されているのみ。これでは将来「なぜ実装はこの形なのか」が追えない
- design.md L153 の inline コメント「後段で `Layer.provideMerge(Env.makeLayer(env))` を合成すれば dependency が閉じる」は、実装と異なる説明になっているため誤解を招く

**Recommended action:**

- design.md L155-173 のスニペットを実装と同形に修正 (`envLayer` 変数化 + `dynamicLoggerLayer.pipe(Layer.provide(envLayer))`)
- design.md L153 の inline コメントを「dynamicLoggerLayer は内側でも Env.Service を要求するため、`provideMerge` で外側に与えるだけでなく、unwrap 後の Layer に対しても明示的に `Layer.provide` で Env を与える必要がある (= Env を 2 箇所に provide する形式)」に書き換える

### M-3 detail: identity-provider's `routes.ts` docstring が 実装 (`frames: { content: 'content' }`) と 矛盾

**Evidence:**

- `js/app/identity-provider/app/routes.ts:4-12` (docstring):

  ```
  Named frames declared in this app. Each entry pairs the JSX `<Frame name>`
  with the `<a rmx-target>` value so the two stay in lock-step.

  The router itself is defined in `app.tsx` against Hono — this module exists
  solely to give `<Frame>` / `<FrameLink rmx-target>` / `isFrameRequest()` a
  single source of truth for frame names.

  ms-01 段階では Frame は宣言のみで未使用。ms-04 / ms-07 で UI を強化する際に活用する。
  ```

- `:13-15`: `export const frames = { content: 'content' } as const`
- 一方、`js/app/feed-platform-web/app/routes.ts:4-12` (docstring):

  ```
  Named frames declared in this app.

  ms-01 段階では Frame ベースの partial swap UI (PageOrFrame) は未採用 (TC-022)。
  本ファイルは将来 ms-04 / ms-07 で UI を強化する際の最小骨格として、
  名前空間と `isFrameRequest` ヘルパだけを保持する。

  `frames` は空オブジェクトのまま、PageOrFrame パターンを採用する時点で
  `content: 'content'` 等のキーを追加する。
  ```

- `:13`: `export const frames = {} as const`

**矛盾の本質:**

- IdP 側は **「Frame は宣言のみで未使用」と書きながら `content: 'content'` を実装に残している**
- web 側は **「frames は空オブジェクトのまま」「`content: 'content'` 等のキーを追加する」と将来形を予告し、実装も空** で一貫
- IdP の `frames = { content: 'content' }` は **TC-022 (`grep -E 'PageOrFrame|createPageOrFrame' = 0 hit`)** には触れないものの、`content` フレームはどこからも参照されない dead code

**Why this matters for readability:**

- 「Frame は宣言のみで未使用」と docstring が書きながら、実装は空でない frames を持つため、後続実装者は「なぜ `content` だけが宣言されているのか」を解読しないといけない
- 2 プロジェクトが Hono + Remix v3 の同形プロジェクトという前提が崩れる。`hono-remix-v3-cloudflare-example` 1:1 コピーベースの統一性が部分的に破れている
- TODO.md T-J notes (L153) に「`app/app.tsx` のコメントから `PageOrFrame` 文字列を削除し TC-022 観測仕様 (... 0 hit) を コメントレベルでも完全に満たす状態に整理」とあるが、`routes.ts` の `frames` 中身までは整理されていない

**Recommended action:**

- IdP の `routes.ts` を web 側と同形に揃える (`frames = {} as const`、docstring も web 側を参考に書き換え)
- もしくは、両プロジェクトで `frames = { content: 'content' }` を採用し、それを参照する素地を `app.tsx` 側に残す形 (= web 側を IdP に合わせる) — ただし「ms-01 = 雛形 + Hello World」という Intent Spec の方針を考えると **web 側を SoT として IdP を空に合わせる方が一貫**
- Step 9 Retrospective の引き継ぎ事項としても候補

### m-2 minor detail: `Document` の二重カリーが何を意味するかコメントがない

**Evidence:**

- `js/app/feed-platform-web/app/ui/document.tsx:12`: `export const Document = () => (props: DocumentProps) => (...)`
- `js/app/identity-provider/app/ui/document.tsx:10`: 同形
- `js/app/hono-remix-v3-cloudflare-example/app/ui/document.tsx:10`: 同形 (= 1:1 コピー由来)

**問題:**

- `Document` の型が `() => (props: DocumentProps) => JSX` という二重カリー
- 通常の React/JSX 慣習では `(props) => JSX` で十分
- 二重カリーが要求される理由は **remix/ui または hono-remix-middleware の `c.render` API の制約** と推測されるが、コード内に説明コメントなし
- 上流 example が同形のため faithful copy は妥当だが、「なぜ二重カリーなのか」を後続実装者が理解できないまま運用されると将来 mistake (e.g. 一段化して動かなくなる) のリスクあり

**Recommended action:**

- 3 プロジェクトの `document.tsx` 上部に「Why double-curry: hono-remix-middleware `remixRenderer` の `c.render(<Document>...)` 経路は Document を call する際にプロパティ無し factory として `Document()` を呼び出し、その戻り関数 `(props) => JSX` を internal で再呼出する 2 段階構造に依存する。一段化すると c.render 経路で TypeError」のような説明コメントを追加 (実機構を 1-2 行で要約)
- もしくは `hono-remix-v3-cloudflare-example` 上流に Issue を起こして共通化

### m-3 minor detail: 3 プロジェクトの `.gitignore` 不揃い

**Evidence:**

| プロジェクト            | `.gitignore` 内容                                                                                                              |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `feed-platform-backend` | `.wrangler/` + `dist/` + `src/bff/worker-configuration.d.ts` + `src/health/worker-configuration.d.ts` (4 行、entry ごとに明示) |
| `feed-platform-web`     | `.wrangler/` + `dist/` + `worker-configuration.d.ts` (3 行)                                                                    |
| `identity-provider`     | `dist/` + `.wrangler/` (2 行のみ、**`worker-configuration.d.ts` 不在**)                                                        |

**確認:**

- `ls /Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/feed-platform-web/worker-configuration.d.ts` → 存在 (504 KB の生成ファイル) → `feed-platform-web/.gitignore` のおかげで tracking 化されない
- `js/app/identity-provider/worker-configuration.d.ts` → 現在は不在 (`vp run setup:cloudflare` を IdP で実行していないため未生成) → ただし将来 `vp run setup` を走らせると生成 → `.gitignore` に登録がないため git tracking 化される懸念

**Why this matters for readability:**

- 命名一貫性 / 構造類似性の観点で、**3 プロジェクトの `.gitignore` が同形でない** ことは将来の混乱要因
- design.md では各プロジェクトの `.gitignore` 構造に言及あり (B-1 / C-1 = "dist/, .wrangler/", A-1 = entry ごとの d.ts 追記) だが、**Web フロント / IdP 両方とも `worker-configuration.d.ts` を ignore すべき** (`vite.config.ts.taskInput.setup.cloudflare` は両プロジェクトで `'worker-configuration.d.ts'` を input に含む)
- `feed-platform-web` だけが対応済みで `identity-provider` は未対応 = T-I コピー時の漏れと推測

**Recommended action:**

- `identity-provider/.gitignore` に `worker-configuration.d.ts` を追加 (1 行追記)
- 3 プロジェクトの `.gitignore` を整える機会に、`design.md` CC-X として「3 プロジェクト共通の .gitignore patterns」節を追加することも検討

## Round history metadata

| Round | Date       | Reviewer instance                 | Round-only Gate |
| ----- | ---------- | --------------------------------- | --------------- |
| 1     | 2026-05-06 | reviewer (readability, initial)   | needs_fix       |
| 2     | 2026-05-06 | reviewer (readability, re-review) | approved        |

Final Gate: `approved`. 0 Major / 0 Blocker findings open, 0 `accepted-as-is`.

### Round 2 サマリ

Round 1 で flagged した Major 3 件すべてが対応 commit と完全に整合する形で解消:

- **M-1** → `900b120` (design.md correction): Component breakdown スニペット 3 箇所 + CC-6 を `Context.Service` に修正、Phase 1 deviation note を 2 箇所追記。`ServiceMap.Service` の残存記述は SC-6 観測仕様の OR パターンとして意図的に保持されており注釈もある。Recommended action「該当スニペット直下に deviation 注記を追加 + CC-6 / Component breakdown は必ず修正」を完全充足。
- **M-2** → `900b120` (design.md correction): `runtime/server.ts` スニペット (L166-179) を実装同形化、`envLayer` 変数化 + `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` 採用、inline コメント (L158, L167-170) と直下 deviation note (L212) で「Env を 2 箇所に provide する形式」の意図が明文化。Recommended action と完全一致。
- **M-3** → `dacf3e4` (T-I/r1): `identity-provider/app/routes.ts:13` を `frames = {} as const` に修正、docstring (L4-12) も `feed-platform-web/app/routes.ts` と同形に書き換え、L11 で「`feed-platform-web/app/routes.ts` と完全同形」と明記。「web 側を SoT として IdP を空に合わせる」Recommended action 採用。

副次的に Round 1 Minor 1 件 (m-3 `.gitignore` 不整合) も `dacf3e4` で解消 (`identity-provider/.gitignore:3` に `worker-configuration.d.ts` 追記、3 プロジェクト整合)。

Round 2 で新規発見した readability finding は **0 件**。残る Minor 6 件 (m-1 / m-2 / m-4 / m-5 / m-6 / m-7) と Info 6 件は Step 9 Retrospective への引き継ぎ材料として `pending` / `(consistency check)` のまま保持 (Major / Blocker ではなく Step 7 Gate を阻害しないため)。

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
