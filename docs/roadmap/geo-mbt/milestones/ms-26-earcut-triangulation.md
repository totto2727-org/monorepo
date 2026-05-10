# Milestone: Earcut Triangulation

- **Milestone ID:** ms-26-earcut-triangulation
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `earcutr` クレート相当の単純多角形三角形分割を Pure MoonBit で port する。穴付き polygon に対応した ear-clipping アルゴリズム。i_overlay や Delaunay (ms-27) と独立で実装可能。

## 到達点 (定性)

- `src/earcut/earcut.mbt` に earcut 本体が実装される
- `triangulate_earcut(polygon) -> Array[Triangle]` が動作する
- 穴 (interior rings) 付き polygon に対応する
- linked list ベースの ear-clipping 実装で、`Triangle` の列を返す
- 退化入力 (面積ゼロ、自交差) に対する挙動が doctest で明文化される
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/earcut/` 全体
- `src/geo/2d/triangulate_earcut.mbt` (公開 API)
- 各 `*_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の `triangulate_earcut` 行を ⛔ → ✅

## 非スコープ

- Delaunay 三角形分割 (ms-27 の責務)
- Voronoi (ms-28 の責務)

## 依存マイルストーン

- ms-15-validation-finalize (Phase 1 確定後を起点とするため)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/earcutr/src/`
- 元アルゴリズム: Mapbox earcut.js
