# Milestone: Topology Basics — CoordinatePosition/Intersects/HasDimensions

- **Milestone ID:** ms-07-topology-basics
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

包含 (`Contains`) や DE-9IM 系の前提となる基礎的なトポロジ判定 (`CoordinatePosition`, `Intersects`) と、Boundary / Inside / Outside の判定基盤を MoonBit に移植する。`Kernel::orient2d` を内部利用するため `ms-05-robust-kernels` 完了後に着手する。

## 到達点 (定性)

- `src/geo/2d/coordinate_position.mbt` に `CoordPos` enum (`Inside` / `Outside` / `OnBoundary`) と `coordinate_position(geometry, coord) -> CoordPos` 相当が実装される
- `src/geo/2d/intersects.mbt` に各ジオメトリ組み合わせの `intersects(a, b) -> Bool` 相当が実装される (Coord/Point/Line/LineString/Polygon/MultiPolygon 等の各組合せ)
- Rust 版 `coordinate_position.rs`, `intersects/*.rs` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/coordinate_position.mbt` + `_test.mbt`
- `src/geo/2d/intersects.mbt` (1 ファイルにまとめるか、`intersects/` ディレクトリに分割するかは Step 3 で決定) + `_test.mbt`

## 非スコープ

- `Contains` / `Within` / `Covers` — ms-08
- DE-9IM `Relate` — ロードマップ非スコープ (将来別ロードマップ)
- 線分交差スイープ (Bentley-Ottmann) — ロードマップ非スコープ

## 依存マイルストーン

- ms-05-robust-kernels: `orient2d` を `intersects` の実装で利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/coordinate_position.rs`, `~/proj/geo/georust-geo/geo/src/algorithm/intersects/` (複数ファイル)
- Rust 版の `Intersects` trait は型ペアごとに impl が分かれているため、MoonBit では `intersects_<a>_<b>(a, b)` の関数群、または `enum Geometry` に対するパターンマッチ単一エントリの 2 形態がありうる。Step 3 で決定
