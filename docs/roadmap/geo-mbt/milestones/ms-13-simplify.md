# Milestone: Simplify (RDP/VW) / Chaikin / RemoveRepeatedPoints

- **Milestone ID:** ms-13-simplify
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリの単純化アルゴリズム (Ramer-Douglas-Peucker、Visvalingam-Whyatt、Chaikin smoothing) と前処理 (重複点除去) を MoonBit に移植する。

## 到達点 (定性)

- `src/geo/2d/simplify.mbt` に `simplify(geometry, epsilon: Double) -> Geometry` (RDP) および `simplify_idx(geometry, epsilon: Double) -> Array[Int]` 相当が実装される
- `src/geo/2d/simplify_vw.mbt` に `simplify_vw(geometry, epsilon: Double)`, `simplify_vw_idx(...)`, `simplify_vw_preserve(...)` (トポロジ保存版) 相当が実装される
- `src/geo/2d/chaikin_smoothing.mbt` に `chaikin_smoothing(linestring, n_iterations: Int) -> LineString` 相当が実装される
- `src/geo/2d/remove_repeated_points.mbt` に `remove_repeated_points(geometry) -> Geometry` 相当が実装される
- Rust 版テストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/{simplify,simplify_vw,chaikin_smoothing,remove_repeated_points}.mbt` + `_test.mbt`

## 非スコープ

- `simplify_vw_preserve` のトポロジ保存版が R-tree を要求する場合は本 port では別実装 (R-tree 非依存) を採用するか、ロジックを限定する。具体は Step 3 で決定
- `linestring_segment` (`LineStringSegmentize`) — 余裕があれば追加

## 依存マイルストーン

- ms-06-vector-distance: ベクトル演算 / 点 - 線分距離を内部利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{simplify,simplify_vw,chaikin_smoothing,remove_repeated_points}.rs`
- VW preserve 版は内部で R-tree を使う Rust 実装になっている可能性 — Step 3 で空間索引非依存版への置換可否を判断
