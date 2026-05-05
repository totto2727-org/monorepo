# Milestone: Bounding & Area — BoundingRect/Area/Dimensions

- **Milestone ID:** ms-04-bounding-area
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

最も基本的な計量 (バウンディングボックス、面積、次元) を MoonBit に移植し、後続の包含・凸包・アフィン演算等が依存できる土台を整える。

## 到達点 (定性)

- `src/geo/2d/bounding_rect.mbt` に `bounding_rect(geometry) -> Option[Rect]` (空ジオメトリは `None`) 相当が実装される
- `src/geo/2d/area.mbt` に `signed_area(geometry) -> Double` および `unsigned_area(geometry) -> Double` 相当が実装される (Polygon は外環符号付き面積から内環の面積を引く)
- `src/geo/2d/dimensions.mbt` に `dimensions(geometry) -> Dimensions` enum (Empty / ZeroDimensional / OneDimensional / TwoDimensional) と `is_empty(geometry) -> Bool` が実装される
- Rust 版 `bounding_rect.rs`, `area.rs`, `dimensions.rs` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/bounding_rect.mbt` + `_test.mbt`
- `src/geo/2d/area.mbt` + `_test.mbt`
- `src/geo/2d/dimensions.mbt` + `_test.mbt`

## 非スコープ

- 重心 (Centroid) — ms-09
- 外接矩形 (MinimumRotatedRect) — 後続マイルストーンで扱う可能性
- 球面・測地面積 (ChamberlainDuquetteArea / GeodesicArea) — ロードマップ非スコープ

## 依存マイルストーン

- ms-03-iteration: 反復ユーティリティが必要 (`CoordsIter` で全座標を走査して min/max を求める)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{bounding_rect,area,dimensions}.rs`
- `Area` の符号は曲線の向き (winding) に依存するため、Rust 版の `signed_area` / `unsigned_area` の意味論を厳密に保つ
- 既存 `mbt/package/geo/src/turf/` には類似機能が一部存在するが、`geo-mbt` は独立実装で進める
