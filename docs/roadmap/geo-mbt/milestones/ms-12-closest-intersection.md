# Milestone: Closest Point / Line Intersection / Locate / Interpolate

- **Milestone ID:** ms-12-closest-intersection
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

線分上の最近点・補間・位置特定や 2 線分の交差点計算など、線分・線形ジオメトリに対する位置ベースの演算を MoonBit に移植する。

## 到達点 (定性)

- `src/geo/2d/closest_point.mbt` に `closest_point(geometry, target: Point) -> Closest` 相当が実装される (`Closest` は `Intersection(Point) | SinglePoint(Point) | Indeterminate` 相当)
- `src/geo/2d/line_intersection.mbt` に `line_intersection(line1, line2) -> Option[LineIntersection]` (`SinglePoint(Point, bool) | Collinear(Line)`) 相当が実装される
- `src/geo/2d/line_locate_point.mbt` に `line_locate_point(line_or_linestring, target: Point) -> Option[Double]` (0..=1 のフラクション) が実装される
- `src/geo/2d/line_interpolate_point.mbt` に `line_interpolate_point(line_or_linestring, fraction: Double) -> Option[Point]` が実装される
- Rust 版 `closest_point.rs`, `line_intersection.rs`, `line_locate_point.rs`, `line_interpolate_point.rs` (および `line_measures/interpolate_point.rs` の Euclidean 部分) のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/{closest_point,line_intersection,line_locate_point,line_interpolate_point}.mbt` + `_test.mbt`

## 非スコープ

- 球面 / 測地 最近点 (`HaversineClosestPoint`) — ロードマップ非スコープ
- `LineStringSegmentize` (線分の n 等分) — 余裕があれば追加。なければ将来検討
- Bentley-Ottmann スイープ — ロードマップ非スコープ

## 依存マイルストーン

- ms-06-vector-distance: ベクトル演算 (dot, magnitude) と Euclidean 距離を内部利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{closest_point,line_intersection,line_locate_point,line_interpolate_point}.rs`
- `line_intersection` は退化ケース (共線、端点接触) を多数持つ — テスト網羅が重要
