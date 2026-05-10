# Milestone: Concave Hull (k-NN + Delaunay-based)

- **Milestone ID:** ms-29-concave-hull
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `geo::algorithm::{concave_hull, k_nearest_concave_hull}` 相当を実装する。Delaunay-based concave hull (alpha-shape) と k-nearest neighbors-based concave hull の 2 系統。

## 到達点 (定性)

- `concave_hull(geometry, alpha) -> Polygon` が動作する (Delaunay edge filtering ベース)
- `k_nearest_concave_hull(geometry, k) -> Polygon` が動作する (k-NN ベース)
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/concave_hull.mbt`
- `src/geo/2d/k_nearest_concave_hull.mbt`
- 各 `*_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- 並列実装

## 依存マイルストーン

- ms-27-delaunay-triangulation

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/concave_hull.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/k_nearest_concave_hull.rs`
