# Milestone: Vector Ops + Euclidean Distance/Length/Bearing

- **Milestone ID:** ms-06-vector-distance
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

2D ベクトル演算 (`Vector2DOps`) と Euclidean 平面における距離・長さ・方位 (`Distance` / `Length` / `Bearing` / `Destination`) のうち平面計算系を MoonBit に移植する。後続の最近点・単純化・距離指標系が依存する基盤。

## 到達点 (定性)

- `src/geo/2d/vector_ops.mbt` に `dot`, `cross_product`, `magnitude`, `magnitude_squared`, `normalize`, `wedge_product`, `is_finite` 等の `Vector2DOps` 相当が実装される
- `src/geo/2d/euclidean.mbt` (または `src/geo/2d/line_measures/euclidean.mbt`) に Euclidean 距離・長さ計算 (`Coord` ↔ `Coord`, `Point` ↔ `Point`, `Point` ↔ `Line`, `Line` ↔ `Line`, `Line` ↔ `Polygon` 等の各組み合わせ) が実装される
- `Bearing` (方位) と `Destination` (距離・方位から目的座標を求める) の Euclidean 実装
- Rust 版 `vector_ops.rs`, `euclidean_distance.rs`, `euclidean_length.rs`, `line_measures/{euclidean,bearing,destination}.rs` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/vector_ops.mbt` + `_test.mbt`
- `src/geo/2d/euclidean.mbt` (距離・長さ・方位を 1 ファイルに集約)
- 各組み合わせの距離関数 — Rust 版で trait `Distance<Other>` の impl 群を MoonBit では関数 `euclidean_distance(a, b)` のオーバーロード相当 (各ジオメトリ型を引数に取る関数群) として実装

## 非スコープ

- 球面距離 (Haversine) / 測地距離 (Geodesic) / Rhumb / Vincenty — ロードマップ非スコープ
- 距離指標 (Frechet / Hausdorff) — ms-14
- 最近点アルゴリズム (`ClosestPoint`) — ms-12

## 依存マイルストーン

- ms-03-iteration: ジオメトリの反復が必要

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{vector_ops,euclidean_distance,euclidean_length}.rs`, `~/proj/geo/georust-geo/geo/src/algorithm/line_measures/{euclidean,bearing,destination,interpolate_line,interpolate_point,length,distance}.rs` の Euclidean 部分のみ
- Rust 版は `MetricSpace` 抽象 (Euclidean / Haversine / Geodesic / Rhumb の trait) を提供するが、本 port では Euclidean 単独の関数群として実装
