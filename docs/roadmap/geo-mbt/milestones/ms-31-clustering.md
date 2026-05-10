# Milestone: Clustering (DBSCAN + KMeans + Outlier Detection)

- **Milestone ID:** ms-31-clustering
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `geo::algorithm::{dbscan, kmeans, outlier_detection}` 相当を実装する。R\*-tree (ms-18) ベースの近傍検索を活用する。

## 到達点 (定性)

- `dbscan(coords, eps, min_pts) -> Array[Cluster]` が動作する
- `kmeans(coords, k) -> KMeansResult` が動作する
- `outlier_detection(coords, options) -> Array[Coord]` が動作する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/dbscan.mbt`
- `src/geo/2d/kmeans.mbt`
- `src/geo/2d/outlier_detection.mbt`
- 各 `*_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- 並列クラスタリング

## 依存マイルストーン

- ms-18-rtree-expansion

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (DBSCAN × 1 + KMeans/Outlier × 1)

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/dbscan.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/kmeans.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/outlier_detection.rs`
