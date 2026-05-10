# Milestone: Centroid / Extremes / Winding / IsConvex / Orient

- **Milestone ID:** ms-09-centroid-extremes
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリの代表点 (重心) や端点 (最北・最南等)、向き (winding order) を扱うアルゴリズム群を MoonBit に移植する。アフィン変換 (ms-10) や凸包 (ms-11) からも参照される。

## 到達点 (定性)

- `src/geo/2d/centroid.mbt` に `centroid(geometry) -> Option[Point]` 相当が実装される
- `src/geo/2d/extremes.mbt` に `extremes(geometry) -> Option[Outcome]` (Outcome は xmin/xmax/ymin/ymax の各端点とインデックス) 相当が実装される
- `src/geo/2d/winding_order.mbt` に `WindingOrder` enum (`Clockwise` / `CounterClockwise`) と `winding_order(linestring) -> Option[WindingOrder]` が実装される
- `src/geo/2d/is_convex.mbt` に `is_convex(linestring) -> Bool` および `is_strictly_convex(linestring) -> Bool` が実装される
- `src/geo/2d/orient.mbt` に `Direction` enum (`Default` / `Reversed`) と `orient(polygon, direction) -> Polygon` が実装される (外環 CCW / 内環 CW の標準形に整える)
- Rust 版各テストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/{centroid,extremes,winding_order,is_convex,orient}.mbt` + `_test.mbt`

## 非スコープ

- `InteriorPoint` (代表内部点) — 余裕があれば追加、なければ将来検討
- `MinimumRotatedRect` — ロードマップ非スコープ
- 球面 / 測地 重心 — ロードマップ非スコープ

## 依存マイルストーン

- ms-04-bounding-area: `signed_area` を centroid / winding で利用
- ms-07-topology-basics: `CoordinatePosition` を一部で利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{centroid,extremes,winding_order,is_convex,orient}.rs`
- `winding_order` は signed area の符号で判定 (Rust 版と同じロジック)
