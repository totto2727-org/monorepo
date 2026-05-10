# Milestone: Delaunay Triangulation (Spade-equivalent)

- **Milestone ID:** ms-27-delaunay-triangulation
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `spade` クレート相当の Delaunay 三角形分割を Pure MoonBit で port する。DCEL データ構造 + 増分挿入 (incremental flip) + 空間検索 (spatial location) を含む。ms-28 (Voronoi) と ms-29 (Delaunay-based concave hull) の前提。

## 到達点 (定性)

- `src/spade/dcel.mbt` に DCEL (Doubly Connected Edge List) が実装される
- `src/spade/delaunay.mbt` に flip-based incremental Delaunay 三角形分割が動作する
- spatial location (R\*-tree backed) で点クエリ O(log n) が動作する
- bulk insert (sorted insertion) でビルド時間が削減される
- constrained Delaunay (制約付き辺の保持) が optional で利用可能
- `triangulate_delaunay(coords) -> Triangulation` が動作する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/spade/` 全体 (DCEL + Delaunay + spatial location)
- `src/geo/2d/triangulate_delaunay.mbt` (公開 API)
- 各 `*_test.mbt.md` + 必要な bench
- `mbt/package/geo-mbt/api-correspondence.md` の `triangulate_delaunay` / `triangulate_spade` 行を ⛔ → ✅

## 非スコープ

- 4D 以上の三角形分割
- 並列ビルド

## 依存マイルストーン

- ms-18-rtree-expansion (spatial location に R\*-tree が必要)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

3 サイクル (DCEL × 1 + Delaunay × 1 + spatial location × 1)

## Notes

- 移植元: `~/proj/geo/spade/src/`
- 数値ロバストネスは `@robust.orient2d` / `@robust.incircle` を活用
