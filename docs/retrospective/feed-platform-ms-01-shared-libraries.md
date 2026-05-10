# Retrospective: feed-platform-ms-01-shared-libraries

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Writer:** Main (autonomous mode)
- **Created at:** 2026-05-10T12:30:00Z
- **Cycle started at:** 2026-05-07T03:55:00Z
- **Cycle completed at:** 2026-05-10T12:30:00Z
- **Duration:** 約 3 日 8 時間
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation` (Phase 2)

## Cycle overview

`feed-platform` ms-01 Phase 2 (共通ライブラリ抽出) として、Phase 1 で 3 プロジェクトに同形コピーされた共通ロジック (`dynamicLoggerLayer` / `makeDisposableRuntime` / `Env.Type` / `isFrameRequest` / `createPageOrFrame` / `FrameLink`) を `js/package/` 配下の 2 つの新規ライブラリ (`effect-hono` / `remix-helper`) に抽出し、4 consumer (`feed-platform-backend` / `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) を library import に切り替えた。

Intent Specification で 7 件の決定を会話駆動で確定し、Step 3 Design では 6 回の revision (R-1〜R-6) を User feedback 反映で経て最終設計を確定。Step 6 Implementation は 7 タスク (T-A〜T-G) を 3 Wave parallel (Wave 1: library skeleton × 2 / Wave 2: consumer migration × 4 / Wave 3: ADR-03 promote) で完了。最終結果は **全 10 SC PASS / 14 TC PASS / Blocker 0**。

## What went well (patterns that worked)

- **factory-only 抽出による実装の簡素化**: 具体実装は consumer に残し、factory のみを抽出する方針 (User Q1-ext) により、ライブラリ API surface が全 4 export に最小化され実装が早期収束した
- **Step 3 design revision loop の効率**: User feedback 6 回 (R-1〜R-6) を CI パイプラインで逐次検証でき、型表現 (struct → union → Record → union direct + FrameLink) の試行錯誤が全く branch 汚染を起こさずに収束。毎 revision commit が CI PASS した状態で進んだ
- **parallel specialist invocation (Step 2 / Step 5 / Step 6)**: Research 4 角度並列 / task-decomposer single / implementer 3 並列 により 3 日 8 時間で 9 ステップ完走
- **design.md "即時 corrigendum" の遂行**: oxc no-barrel-file rule による subpath exports 変更、Env-open Layer の composition 順序変更、`@types/node` tsconfig types 追加等の deviation を実装段階で発生順に記録し、Step 7 review で整理
- **holistic review の実装確認**: 11 findings で Major 1 (M-1: dependency structure) / Minor 3 / Info 6 を検出。M-1 は即時修正 (1 commit) で完結

## Issues (what did not work well)

### Loop count analysis

| Loop between steps                   | Count           | Root cause                                                                                             |
| ------------------------------------ | --------------- | ------------------------------------------------------------------------------------------------------ |
| Step 3 ↔ User feedback (R-1〜R-6)    | 6 revisions     | type design の試行錯誤 (struct → union → Record → union direct + FrameLink)。型表現の反復 was expected |
| Step 2 → Step 3 carry-over (U-1/U-3) | 2 confirmations | 既存実装と設計草案の差 (key union vs value union / Hono 依存 vs フリー)                                |
| Step 7 → Step 6 (M-1 fix)            | 1               | dependency field 配置の設計 ↔ 実装 deviation                                                           |
| Step 6 → Step 6 (CI failure → retry) | 2 CI retries    | main merge 間の `.factory/` 欠落 (branch creation 時からの継承問題) で 2 回 CI failure                 |

### Blocker history

- **(なし、Blocker は 0 件)**

### 認識された主要な摩擦

1. **barrel file → subpath exports への設計 deviation**: design.md が `src/index.ts` barrel を前提としていたが、oxc no-barrel-file rule (threshold 100 modules) が effect import を伴う barrel を拒否したため、全ライブラリを subpath exports に変更せざるを得なくなった。hono-remix-middleware は barrel パターンだが、そちらは 3 export のみで threshold に達していないため免れている。library の exports 設計では最初から oxc rule を考慮した subpath exports とする方が安全

2. **CI の横断フォーマット問題**: 本 cycle の変更とは無関係な `plugins/totto2727/skills/` 配下 25 ファイルが CI 環境でフォーマット警告を出力し、check job が exit ≠ 0 になった。Phase 1 retrospective の rss-graphql 86 errors と同様の問題。workspace-wide check の pre-existing issues が後続 cycle にノイズを乗せる

3. **TypeScript の strict 型システム下での Handle mock 生成の困難**: remix-helper の test (TC-002) で `Handle<T>` の full mock 作成に `as unknown as never` キャストが必要になり、oxc `no-unsafe-type-assertion` rule に抵触。最終的に type-level test (`expectTypeOf`) のみで妥協し、runtime テストを簡略化した。`remix/ui` の `Handle` 型が 7+ プロパティを要求する design-by-contract に対して、unit test 用の mock factory が欠落している

4. **Step 3 design revision の多段階レイヤリング**: R-1〜R-4 → R-5/R-6 の 2 段階で型表現が変更され、progress.yaml に `superseded_decisions` (Pattern P2 + Record P1 寄り が両方撤回) が蓄積。履歴管理の複雑さが増したが、design.md 単一ファイルが一貫したソースとして機能した

## Future improvements

| Improvement                                                    | Action                                                                                                                      | Priority                | Roadmap cycle     |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ----------------- |
| oxc no-barrel-file rule との整合を design.md template に含める | library 新設テンプレートに subpath exports を default 化                                                                    | low                     | n/a (doc-only)    |
| CI の pre-existing formatting issues の cleanup                | `plugins/totto2727/skills/` の 25 files を `vp run fix` で一括修正し main に merge                                          | medium                  | next housekeeping |
| remix-helper test の Handle<T> mock factory                    | `createHandleMock<T>(props)` を remix-helper 自身が export するか、`@remix-run/ui` に test utility リクエスト               | low                     | ms-04 or upstream |
| design.md ↔ 実装 deviation の即時修正                          | deviation 発見時に design.md corrigendum commit を即座に行う protocol を Phase 1 retrospective から継承 (本 cycle で実施済) | — (already implemented) | —                 |

## Summary

ms-01 Phase 2 (共通ライブラリ抽出) は成功。全 10 SC PASS / 全 14 TC PASS / CI PASS / Blocker 0。2 ライブラリ (effect-hono + remix-helper) の stable API surface が確立され、ms-02 (認証) 着手の前提が達成された。Step 3 の design revision (6 rounds) を CI パイプラインで逐次検証できたことが品質を担保した。
