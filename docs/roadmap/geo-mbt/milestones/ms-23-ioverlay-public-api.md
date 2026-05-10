# Milestone: i_overlay Public BooleanOps API + Line Clipping

- **Milestone ID:** ms-23-ioverlay-public-api
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

ms-22 までで揃った overlay graph + extraction の上に、float 座標適応層 (scaling / FloatPointAdapter) を載せ、`geo::BooleanOps` に対応する公開 API を提供する。`Polygon` / `MultiPolygon` 同士の intersection / union / difference / xor / unary_union と、`string/clip` 由来の line clipping もここに含める。Phase 1 の Sutherland-Hodgman 実装はこの段階で general-purpose 実装に置き換える。

## 到達点 (定性)

- `src/i_overlay/float/overlay.rs` 相当の `FloatOverlay` が MoonBit に port され、`OverlayOptions` (preserve_input_collinear / output_direction / preserve_output_collinear / min_output_area / ogc / 精度クリーンアップ) を含む
- `src/i_overlay/float/scale.mbt` で float→int / int→float 変換が動作する
- `src/i_overlay/float/relate.mbt` (float 版 relate) が動作する (DE-9IM ms-20 と棲み分け確認)
- `src/i_overlay/float/clip.mbt` (string clipping) が動作する
- `src/geo/2d/bool_ops.mbt` の API が拡充され、以下が利用可能になる:
  - `intersection(self, other) -> MultiPolygon`
  - `union(self, other) -> MultiPolygon`
  - `difference(self, other) -> MultiPolygon`
  - `xor(self, other) -> MultiPolygon`
  - `unary_union(self) -> MultiPolygon`
  - `clip_line(self, line) -> MultiLineString` (line clipping)
- `BooleanOps` トレイトが定義され、`Polygon` / `MultiPolygon` / `Geometry` 等に impl される
- 既存の `intersection_sutherland_hodgman` / `intersection_polygon_rect` は backward-compatible に残し、内部実装を新エンジン経由に切替える
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/i_overlay/float/` 全体
- `src/geo/2d/bool_ops.mbt` 全面拡充 (新トレイト + 全 BooleanOp)
- `src/geo/2d/bool_ops_test.mbt.md` 拡充
- `mbt/package/geo-mbt/api-correspondence.md` の `bool_ops` 行を 🟡 → ✅
- Phase 1 の `bool_ops.mbt` ヘッダコメント (将来作業の記述) を最新状態に更新

## 非スコープ

- mesh / offset / stroke (ms-24 の責務)
- stitch / repair_polygon (ms-25 の責務)

## 依存マイルストーン

- ms-22-ioverlay-graph

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (float adapter × 1 + 公開 API + line clipping × 1)

## Notes

- 移植元:
  - `~/proj/geo/i_overlay/iOverlay/src/float/` 全体
  - `~/proj/geo/i_overlay/iOverlay/src/string/clip.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/bool_ops/`
- `OverlayOptions` のデフォルト値はサイクル Step 3 で決定 (upstream Default 採用が第 1 候補)
