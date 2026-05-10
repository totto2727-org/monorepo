# Milestone: DE-9IM Relate

- **Milestone ID:** ms-20-relate-de9im
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

`relate` (Dimensionally Extended 9-Intersection Model) を実装する。これは contains / covers / within / intersects / disjoint / touches / crosses / overlaps / equals の論理基盤となる単一の述語。

## 到達点 (定性)

- `relate(g1, g2) -> IntersectionMatrix` が任意の Geometry × Geometry に対して動作する
- `IntersectionMatrix` 上の `is_contains` / `is_covers` / `is_within` / `is_intersects` / `is_disjoint` / `is_touches` / `is_crosses` / `is_overlaps` / `is_equals` が動作する
- 9-intersection matrix のパターンマッチ (`matches("T*F**F***")`) が動作する
- 既存の pairwise free fn (contains_polygon_polygon 等) は relate-based impl に書き換えられる (backward-compatible に維持)
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/relate.mbt`
- `src/geo/2d/relate/intersection_matrix.mbt`
- `src/geo/2d/relate/edge_end_builder.mbt` 他 sweep ベースの内部構造
- `src/geo/2d/relate_test.mbt.md` (DE-9IM 9-cell の各組み合わせを doctest 化)
- 既存 contains/covers/intersects/within の relate-based 化
- `mbt/package/geo-mbt/api-correspondence.md` の `relate` 行を ⛔ → ✅

## 非スコープ

- 数値ロバストネス向上 (i_overlay の整数座標化は別マイルストーン)
- 並列 relate

## 依存マイルストーン

- ms-19-sweep-infrastructure

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (intersection matrix 構築とパターンマッチ API を別サイクルに分離)

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/relate/`
- DE-9IM 仕様: ISO 19125 / Egenhofer & Herring 1991
