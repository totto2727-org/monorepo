# Review Report: test-quality

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** test-quality — SC / TC / smoke test 設計と実装の整合、テストの粒度・網羅性
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** needs_fix
- **Round count:** 1

## Findings list (core)

| ID  | Severity | Finding                                                                                                                                                                                            | Status  | Detected Round | Resolved commit | Notes                                                                                                          |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------------- | --------------- | -------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `feed-platform-web/app/smoke.test.ts` の smoke test が `Health` Service を一切踏まず Greeting のみで終わるため、`Layer.effect` (= 1 依存 Service) 経路 と `Env` 注入経路 が backend / IdP より弱い | pending | 1              | -               | 詳細 [detail](#m-1-detail-feed-platform-web-smoke-test-が-health-を踏まない)                                   |
| M-2 | Major    | TC-004 の Pass criterion (`vp run --filter <pkg> test` 出力に `1 passed` 以上) を smoke test 1 件 (web) で満たすか定義不明瞭。SC-3 と TC-004 両方の観測表現で `≥ 1` が同一観測に縮退している       | pending | 1              | -               | 詳細 [detail](#m-2-detail-tc-004-と-tc-005-の観測重複)                                                         |
| m-1 | Minor    | `Logger.unwrap` (= `dynamicLoggerLayer`) を含む Runtime 全体の構築が smoke test 経路で検証されていない (TC-013 は静的 grep のみ、ランタイム動作確認は Step 8 でも自動化されない)                   | pending | 1              | -               | 詳細 [detail](#m-1-minor-detail-loggerunwrap-経路の動作未検証)                                                 |
| m-2 | Minor    | `describe` / `test` 文言が「期待する出力」しか語らず「Effect Service の Layer 合成 + runPromise 経路」という観測意図を明示しない (TC-004 が `scenario` style である理由が test name から読めない)  | pending | 1              | -               | 詳細 [detail](#m-2-minor-detail-test-名が-scenario-を表現しない)                                               |
| m-3 | Minor    | `feed-platform-web` smoke が `Layer` を import せず `Greeting.layer` を直接 `Effect.provide` に渡している。3 プロジェクトで「Layer 合成パターン」としての統一性が崩れている                        | pending | 1              | -               | 詳細 [detail](#m-3-minor-detail-3-プロジェクト間で-layer-合成形が不揃い)                                       |
| m-4 | Minor    | `it` / `test` の選択基準が明示されていない (3 プロジェクトとも `test` を採用しているが ultracite の `prefer-it` ルール等の方針が design.md に未記載)                                               | pending | 1              | -               | 既存 lint が PASS するなら `test` 採用で問題なし。design.md / qa-design.md に「`test` を採用」と一行記録を推奨 |
| m-5 | Minor    | smoke test に否定 / エラー経路の最小例 (= Service 解決失敗時の挙動 / Effect 失敗時の expect.rejects) が一切ない。Layer 解決パスのうち成功側のみカバー                                              | pending | 1              | -               | 雛形整備サイクルでは過剰だが、ms-02 以降の参照点として Greeting の `Effect.fail` 例 1 件を残す価値はある       |
| i-1 | Info     | `vitest.config.*` を新設しない方針 (CC-5) は `vite-plus/test` が「workspace 単位 Vitest」として動く前提に依存。設定移行が必要になる時の経路を design.md L911-919 に追記しておくと将来安心          | -       | 1              | -               | 観察。ms-02 で「browser test / Worker テスト環境分離」が発生したら `vitest.config.ts` 新設が必要になる         |
| i-2 | Info     | TC-021 の app/ 配下 4 ファイルチェック (`entry.worker.ts` / `app.tsx` / `assets/entry.ts` / `ui/document.tsx`) は smoke test 経路では一切踏まれない (= 構造観測のみ)                               | -       | 1              | -               | 観察。Step 8 の find/ls で完結する範囲であり test-quality アスペクトの責務外                                   |
| i-3 | Info     | TC-024 / TC-025 (ADR ファイル存在 + 主要セクション) は静的 grep として適切だが、ADR 本文の更新で誤って見出しレベル変更があった場合に検出できないリスクあり (= `^## ` 完全一致依存)                 | -       | 1              | -               | 観察。検出側 (validator) の正規表現を `^##\s+` に揃えると更にロバスト                                          |
| i-4 | Info     | ms-02 以降の認証 end-to-end test / DB seed test を見据えると、本サイクルの smoke 構造 (Effect.runPromise + Layer.provide) は出発点として適切。`Greeting` を 1 例、`Health` を 1 例残しておけば十分 | -       | 1              | -               | 観察。Q10 への回答 = 出発点として現状で問題なし。M-1 解消で更に強化される                                      |

## Detail sections

### M-1 detail: feed-platform-web smoke test が Health を踏まない

**Evidence:**

- `js/app/feed-platform-web/app/smoke.test.ts:1-15` — Greeting のみ、Layer 合成なし、Env 注入なし
- `js/app/identity-provider/app/smoke.test.ts:1-27` — Greeting + Health の 2 ケース、`Layer.provide(Env.makeLayer(...))` で Env 注入
- `js/app/feed-platform-backend/src/smoke.test.ts:1-17` — Health のみ、`Layer.provide(Env.makeLayer(...))` で Env 注入
- `js/app/feed-platform-web/app/feature/health.ts:14-22` — `Health.layer = Layer.effect` (Env 依存あり) は web にも生成されているが smoke で使われていない

**Why it matters:**

- design.md L930-960 (CC-7) は **3 プロジェクト共通**で Effect skeleton 5 ファイル (env / greeting / health / runtime/server / runtime/hono) を要求している。design.md L944 は「3 段階 (succeed / sync / effect) を **すべて**採用」と明示。
- TC-004 の検証意図は「Effect Service の Layer 合成 → Effect.runPromise の連続ステップ」(qa-flow.md L65 / qa-design.md L65)。`Layer.sync` 単発 (web 現状) は **Layer 合成ステップが消失**し、`scenario` style の意義が弱まる。
- IdP は Greeting + Health 2 件 / backend は Health 1 件 / web は Greeting 1 件 という **3 プロジェクト間で smoke の網羅範囲が大きく非対称**。design.md L960 の「Effect skeleton (5 ファイル) は完全に同形コピー。差は entry 形 / wrangler / vite plugin / middleware 順序の 4 点に閉じる」という方針と smoke test の網羅範囲は背反していないとはいえ、smoke 設計面でも対称性を保つ方が将来引き継ぎコストが下がる。

**Recommended action:**

- `feed-platform-web/app/smoke.test.ts` に `Health.check` テストを 1 件追加し、`Layer.provide(Env.makeLayer({ ENV: 'development' }))` 経路を踏ませる。IdP と同形にすると 3 プロジェクト間の対称性が確保される。

### M-2 detail: TC-004 と TC-005 の観測重複

**Evidence:**

- qa-design.md L65 (TC-004): "3 プロジェクトすべてで `vp run test` が exit 0 ... smoke test が ≥ 1 件 PASS"
- qa-design.md L66 (TC-005): "`vp run -r build` がワークスペース全体で exit 0 ..."
- intent-spec.md L135-136 (SC-3): "各プロジェクトで `vp run test; echo $?` が `0` かつ Vitest 出力で `passed` 件数 ≥ 1"

**Why it matters:**

- 元々の review question 8 (TC-004 vs TC-005) は誤読 (TC-005 は build であり、test 件数とは無関係)。**真に問題なのは TC-004 の Pass criterion**: 「`1 passed` 以上、`0 failed`」(qa-design.md L65 Pass criterion 列) という観測が、smoke test 1 件のみのプロジェクト (web / backend) と複数 (IdP の 2 件) で **同じ pass 判定**になる。SC-3 が「smoke test ≥ 1」を要求しているため違反ではないが、TC-004 を `scenario` style と分類した意義 (= 連続ステップ) が一律 1 件で薄れる。
- M-1 の解消 (web に Health 追加) で IdP / web は 2 件、backend は 1 件のままとなるが、backend は `Health.check` (Layer.effect + Env 注入) という **複合 Layer 合成 + runPromise** の最小条件は満たす。M-1 解消後は TC-004 の `scenario` 性が 3 プロジェクト全体で担保される。

**Recommended action:**

- M-1 を解消すれば本件は併せて解消する。追加対応は不要。Step 8 validator は `vp run --filter <pkg> test` の出力で `passed` 件数を観測する際、件数の絶対値ではなく「smoke test ≥ 1 件 PASS かつ 0 failed」を Pass criterion として記録するよう留意。

### m-1 minor detail: Logger.unwrap 経路の動作未検証

**Evidence:**

- `js/app/feed-platform-backend/src/feature/runtime/server.ts:11-31` — `dynamicLoggerLayer` (Layer.unwrap + Env.Service) を含む Runtime 構築
- TC-013 (qa-design.md L74): "grep -E 'Layer\\.unwrap' が hit、`import.meta.env.PROD` が hit しない (0 件)" — **静的 grep のみ**
- smoke test 3 件のいずれも `Runtime.make(...)` / `ManagedRuntime` 経由で Logger 統合 runtime を起動していない

**Why it matters:**

- design.md L945 が user gate review refinement で確定した重要設計事項 (`Logger.unwrap` + `Env.Service` 経由判定) の **動作検証**は Step 8 でも自動化されず、CI 経路では「ファイル内で `Layer.unwrap` がコード上現れる」だけが PASS 条件。実装が `Layer.unwrap` を呼び出すが値を捨てる等の偽陽性は検出されない。
- 一方で、雛形整備の性格上、Logger 切替の挙動 (PROD / DEV) を観測するのは Vitest では困難 (環境依存 + console capture が必要)。**ms-01 で smoke にこれを含めるのは過剰**。

**Recommended action:**

- 必須対応なし。Step 9 retrospective の「次サイクル検討事項」として「Runtime 全体構築 (= `Runtime.make(env)` 呼び出し → 構築失敗しない / dispose まで通る) を踏む smoke を ms-02 以降で検討」を残すと良い。または、本サイクル内で 4 行追加で対応するなら、各 smoke に `await using runtime = Runtime.make({ ENV: 'development' })` を 1 行 + `expect(runtime.instance).toBeDefined()` 程度を加えると Logger.unwrap 経路の **構築段階だけは**実行する smoke になる。

### m-2 minor detail: test 名が scenario を表現しない

**Evidence:**

- `js/app/feed-platform-backend/src/smoke.test.ts:8` — `'Health.check returns ok with env injected from layer'`
- `js/app/feed-platform-web/app/smoke.test.ts:7` — `'Greeting.greet returns expected string via Layer.provide + Effect.runPromise'`
- `js/app/identity-provider/app/smoke.test.ts:9` — `'Greeting.greet returns "Hello, identity-provider"'`

**Why it matters:**

- web は「`Layer.provide + Effect.runPromise` 経由」を test 名に明記しており、TC-004 の `scenario` style 意図 (= Layer 合成 → runPromise → 結果照合の連続ステップ; qa-design.md L65) を読み取れる。一方で backend / IdP の test 名は「期待結果」のみで、観測意図が test 名から欠落している。
- describe ブロック名 (`<project> smoke`) で「smoke = 最小経路通過確認」は伝わるため致命的ではないが、test 名が揃っていないと「テスト粒度が同じか」をレビュアが文字列だけで判断できない。

**Recommended action:**

- 3 プロジェクトの test 名を「`<Service>.<method>` over `Layer.provide` + `Effect.runPromise`」のような共通パターンで揃えると quality の伝達効率が上がる。または逆に、web も backend / IdP の簡潔形に揃える。**統一されていることが重要**で、形式自体はどちらでも良い。

### m-3 minor detail: 3 プロジェクト間で Layer 合成形が不揃い

**Evidence:**

- `js/app/feed-platform-backend/src/smoke.test.ts:13` — `Health.layer.pipe(Layer.provide(Env.makeLayer({ ENV: 'development' })))` で **明示的な Layer 合成変数**を作る
- `js/app/identity-provider/app/smoke.test.ts:23` — backend と同形の `Layer.provide` 合成
- `js/app/feed-platform-web/app/smoke.test.ts:12` — `Effect.provide(program, Greeting.layer)` の **直書き** (Layer 合成なし、`Layer` import なし)

**Why it matters:**

- `Greeting.layer` は依存ゼロの `Layer.sync` のため Layer 合成不要だが、web のみ `Layer` を import せず合成の形が登場しない結果、3 プロジェクト間でレビュ観点が変わる。M-1 解消 (Health 追加) と併せて「web も Layer 合成形を 1 件持つ」状態にすると、CC-7 の「3 段階 Layer constructor 採用」が smoke でも観測点として現れる。

**Recommended action:**

- M-1 解消で `Health.layer.pipe(Layer.provide(Env.makeLayer(...)))` が web に追加されれば本件も自動解消。Greeting 単独 case を残すか統合するかは作業者裁量。

## Round history meta

| Round | Date       | reviewer instance               | Single-Round Gate |
| ----- | ---------- | ------------------------------- | ----------------- |
| 1     | 2026-05-06 | reviewer (test-quality, Round1) | needs_fix         |

Final Gate: `needs_fix`. Major 2 件 (M-1 / M-2) が要対応。M-2 は M-1 解消で併せて解消する見込み。Minor 5 件はすべて Retrospective 持ち越し可。Info 4 件は記録のみ。
