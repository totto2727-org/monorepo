# Milestone: Indexed Algorithms (`indexed_*`)

- **Milestone ID:** ms-30-indexed-algorithms
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `geo::algorithm::indexed` 相当を実装する。R\*-tree (ms-18) を利用して `contains` / `intersects` / `nearest` などをバッチ処理する高速 API。

## 到達点 (定性)

- `IndexedGeometry` 等のラッパー型が定義され、内部で R\*-tree を保持する
- `IndexedGeometry::contains_coord(coord) -> Bool`、`IndexedGeometry::intersects_geometry(other) -> Bool`、`IndexedGeometry::nearest_coord(coord) -> Coord?` が動作する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/indexed.mbt`
- `src/geo/2d/indexed_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の `indexed` 行を ⛔ → ✅

## 非スコープ

- 並列クエリ

## 依存マイルストーン

- ms-18-rtree-expansion

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/indexed.rs` (要確認)
