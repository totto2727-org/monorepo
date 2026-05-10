# Milestone: Geometry Primitives — Point/Line/LineString/Polygon/etc.

- **Milestone ID:** ms-02-primitives
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

`geo-types` 由来の 11 種の 2D ジオメトリ型 (Point / MultiPoint / Line / LineString / MultiLineString / Polygon / MultiPolygon / Rect / Triangle / GeometryCollection / Geometry enum) を `f64` 固定で MoonBit に移植し、Rust 版の同等テストとともに利用可能にする。

## 到達点 (定性)

- `src/geo/2d/type/` に以下の MoonBit ファイルが揃う: `point.mbt`, `multi_point.mbt`, `line.mbt`, `line_string.mbt`, `multi_line_string.mbt`, `polygon.mbt`, `multi_polygon.mbt`, `rect.mbt`, `triangle.mbt`, `geometry_collection.mbt`, `geometry.mbt` (Geometry enum)
- 各型に Rust 版相当のコンストラクタ (`Point::new(x, y)`, `LineString::new(coords)`, `Polygon::new(exterior, interiors)`, `Rect::new(min, max)` 等) と基本アクセサ (`x()`, `y()`, `coord()`, `start()`, `end()`, `exterior()`, `interiors()`, `min()`, `max()` 等) を提供
- `Geometry` enum は 10 種のバリアント (Point / Line / LineString / Polygon / MultiPoint / MultiLineString / MultiPolygon / GeometryCollection / Rect / Triangle) を持つ
- Rust 版各 `geometry/<type>.rs` の `#[cfg(test)]` テストが `<type>_test.mbt` として同等移植され PASS する
- `vp run --filter @totto2727/geo-mbt check && test` が PASS する

## スコープ

- `src/geo/2d/type/{point,multi_point,line,line_string,multi_line_string,polygon,multi_polygon,rect,triangle,geometry_collection,geometry}.mbt` および対応する `_test.mbt`
- Rust 版 `geo-types/src/macros.rs` の `point!`, `line!`, `polygon!` 相当の補助コンストラクタ関数 (マクロは MoonBit に存在しないため関数化)
- `Rect` の不変条件 (min ≤ max) は内部で必ず正規化される (Rust 版と同じ)
- 既存 `mbt/package/geo/src/type/` の同名モジュールは参考 (構造は流用しすぎず、Rust 版の API に寄せる)

## 非スコープ

- 反復系 (CoordsIter / LinesIter / MapCoords) — ms-03
- 境界・面積 — ms-04
- Display / Debug の整形出力 — Rust 版の `Debug` derive 相当のみ提供 (詳細整形は不要)
- WKT パーサ / GeoJSON 変換 — `@totto2727/geo` 側に既存、本パッケージでは扱わない
- `Point::distance()` 等のアルゴリズム — ms-06 以降

## 依存マイルストーン

- ms-01-foundation: `Coord` 型と命名規則の確定が前提

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時 (Step 2): 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo-types/src/geometry/{point,multi_point,line,line_string,multi_line_string,polygon,multi_polygon,rect,triangle,geometry_collection,mod}.rs`
- `LineString` の closed 判定 (`is_closed()`)、`Polygon` の exterior が `Ring` (LineString の特殊化) であることなどは Rust 版の意味論を保つ
- MoonBit `Array[T]` を内部表現として使用 (Rust 版の `Vec<T>` に対応)
- パターンマッチで型分岐できる `Geometry` enum は MoonBit の enum でほぼそのまま表現可能
