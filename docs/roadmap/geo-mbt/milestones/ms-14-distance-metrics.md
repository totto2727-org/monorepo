# Milestone: Frechet / Hausdorff Distance / Densify

- **Milestone ID:** ms-14-distance-metrics
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

線形・面ジオメトリ間の高次距離指標 (Frechet 距離 / Hausdorff 距離) と、線分上に点を補完する `Densify` を MoonBit に移植する。

## 到達点 (定性)

- `src/geo/2d/frechet_distance.mbt` に `frechet_distance(linestring1, linestring2) -> Double` 相当が実装される
- `src/geo/2d/hausdorff_distance.mbt` に `hausdorff_distance(geometry1, geometry2) -> Double` 相当が実装される
- `src/geo/2d/densify.mbt` に `densify(geometry, max_segment_length: Double) -> Geometry` 相当 (Euclidean 版) が実装される
- Rust 版テストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/{frechet_distance,hausdorff_distance,densify}.mbt` + `_test.mbt`

## 非スコープ

- 球面 Densify (`DensifyHaversine`) — ロードマップ非スコープ

## 依存マイルストーン

- ms-06-vector-distance: 点 - 点 / 点 - 線 距離を内部利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{frechet_distance,hausdorff_distance}.rs`, `~/proj/geo/georust-geo/geo/src/algorithm/line_measures/densify.rs` の Euclidean 部分
