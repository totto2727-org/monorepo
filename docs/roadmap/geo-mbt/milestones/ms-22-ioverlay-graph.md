# Milestone: i_overlay Graph + Extraction

- **Milestone ID:** ms-22-ioverlay-graph
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

ms-21 で組んだ segment / split 層の上に、overlay graph (DCEL 風グラフ) を構築する core 層を実装する。fill rule と overlay rule に基づく結果抽出ロジックも本マイルストーンに含める。

## 到達点 (定性)

- `src/i_overlay/core/graph_builder.mbt` で segment 集合からグラフ (頂点・辺・面) が構築できる
- `src/i_overlay/core/vector_edge.mbt` の vector edge 表現が動作する
- `src/i_overlay/core/segment.mbt` で internal segment 構築が動作する
- `src/i_overlay/core/extract.mbt` で `BooleanExtractionBuffer` 経由の結果抽出が動作する
- `src/i_overlay/core/fill_rule.mbt` (EvenOdd / NonZero / Positive / Negative) が enum として定義される
- `src/i_overlay/core/overlay_rule.mbt` (Subject / Clip / Intersect / Union / Difference / InverseDifference / Xor) が enum として定義される
- `src/i_overlay/core/predicate.mbt` (orient / dot / cross 等の整数座標版) が動作する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/i_overlay/core/` 全体
- 各 `*_test.mbt.md`
- ms-21 で作った segm/split 層との結合テスト

## 非スコープ

- 公開 BooleanOps API (ms-23 の責務)
- float 適応層 (ms-23 の責務)
- mesh / stroke / offset (ms-24 の責務)

## 依存マイルストーン

- ms-21-ioverlay-foundation

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (graph builder × 1 + extraction/rules × 1)

## Notes

- 移植元: `~/proj/geo/i_overlay/iOverlay/src/core/`
- 上流の `IntOverlayOptions` / `Overlay` / `ContourDirection` / `ShapeType` を MoonBit 側でどう表現するかはサイクル Step 3 で確定
