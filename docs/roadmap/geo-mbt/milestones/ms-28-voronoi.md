# Milestone: Voronoi (Delaunay dual)

- **Milestone ID:** ms-28-voronoi
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

ms-27 で実装した Delaunay 三角形分割の双対グラフとして Voronoi 図を提供する。

## 到達点 (定性)

- `voronoi(coords) -> Voronoi` が動作する
- Voronoi の各 cell が `MultiLineString` または `Polygon` として取得できる
- 境界処理 (clip to bounding rect) が動作する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/voronoi.mbt`
- `src/geo/2d/voronoi_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の `voronoi` 行を ⛔ → ✅

## 非スコープ

- 重み付き Voronoi (Power diagram)
- 球面 Voronoi (geographic 系は ms-32〜ms-33 で扱う)

## 依存マイルストーン

- ms-27-delaunay-triangulation

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/voronoi.rs` (要確認)
- Spade は Voronoi も提供しているため `~/proj/geo/spade/src/` 内も参照
