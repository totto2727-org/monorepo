# Milestone: Iteration & Traversal — CoordsIter/LinesIter/MapCoords

- **Milestone ID:** ms-03-iteration
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリ型を横断する反復・写像のユーティリティ (`CoordsIter`, `LinesIter`, `MapCoords` 系) を MoonBit に移植し、後続のアルゴリズム実装が共通基盤として利用できる状態にする。

## 到達点 (定性)

- `src/geo/2d/coords_iter.mbt` に `coords_iter(geometry) -> Iter[Coord]` および `coords_count(geometry) -> Int` 相当が実装される (各ジオメトリ型ごとの分岐を提供)
- `src/geo/2d/lines_iter.mbt` に `lines_iter(geometry) -> Iter[Line]` 相当 (LineString / Polygon / MultiLineString / MultiPolygon を Line セグメントに分解)
- `src/geo/2d/map_coords.mbt` に `map_coords(geometry, fn(Coord) -> Coord) -> Geometry` および in-place 版 `map_coords_in_place(geometry, fn(Coord) -> Coord) -> Unit` 相当が実装される
- Rust 版 `coords_iter.rs`, `lines_iter.rs`, `map_coords.rs` の `#[cfg(test)]` テストが移植され PASS
- `vp run --filter @totto2727/geo-mbt check && test` PASS

## スコープ

- `src/geo/2d/coords_iter.mbt` + `_test.mbt`
- `src/geo/2d/lines_iter.mbt` + `_test.mbt`
- `src/geo/2d/map_coords.mbt` + `_test.mbt`
- 各ジオメトリ型に対する型分岐実装 (Rust の trait impl を MoonBit の関数 + パターンマッチで表現)

## 非スコープ

- 境界 / 面積 — ms-04
- 距離計算 — ms-06
- `MapCoords` のフォルブル変換 (`TryMapCoords`) — 必要が出たマイルストーンで追加

## 依存マイルストーン

- ms-02-primitives: 反復対象のジオメトリ型が必要

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/coords_iter.rs`, `lines_iter.rs`, `map_coords.rs`
- Rust 版は `Iterator` trait で実装、MoonBit では `Iter[T]` を返す関数として提供
- `Vector2DOps` (`vector_ops.rs`) は ms-06 で扱う (反復系の責務外)
