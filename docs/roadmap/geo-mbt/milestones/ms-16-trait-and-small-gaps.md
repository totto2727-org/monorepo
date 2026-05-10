# Milestone: Trait Surface Expansion + Small ⏳ Items

- **Milestone ID:** ms-16-trait-and-small-gaps
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

Phase 1 で残った API 表面の細かい差分を一掃する。pairwise predicate (`Contains` / `Covers` / `Intersects` / `Within`) のトレイト統合と、`api-correspondence.md` に ⏳ として列挙されている小規模未着手項目をまとめて消化する。

## 到達点 (定性)

- pairwise predicate (Contains / Covers / Intersects / Within) が単一の `Geometry × Geometry -> Bool` トレイト経由で呼び出せるようになり、各 `*_geometry_geometry` 系 free fn は trait impl の private helper に格下げされる
- `Polygon::empty()` ファクトリが追加される (Rust upstream に揃える)
- `Triangle::new(v0, v1, v2)` が CCW 強制版として追加される (現状の `Triangle::Triangle` は `unchecked_winding` 相当として残す)
- `AffineTransform::{inverse, scaled, translated, rotated, skewed, compose_many, is_identity}` が実装される
- `MultiPoint::from_point` / `MultiPoint::from_array` 等の上流 `From` 系 ergonomic helper が追加される
- `Extreme<T>` (index + coord) が追加され `HasExtremes` の戻り値を upstream 互換に揃える
- `simplify_vw_idx` (Visvalingam-Whyatt インデックス版) と `simplify_vw_preserve` (端点保存版) が追加される
- `ContainsProperly` トレイトが追加される
- 上記すべてに blackbox + doctest が揃い `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/contains.mbt` / `covers.mbt` / `intersects.mbt` / `winding_order.mbt` (within 統合) のトレイト化リファクタ
- `src/geo/2d/type/polygon.mbt` (`empty` 追加)
- `src/geo/2d/type/triangle.mbt` (`new` CCW 強制版追加)
- `src/geo/2d/affine_transform.mbt` (残メソッド追加)
- `src/geo/2d/type/multi_point.mbt` (`from_point` / `from_array` 追加)
- `src/geo/2d/extremes.mbt` (`Extreme<T>` 追加)
- `src/geo/2d/simplify_vw.mbt` (`simplify_vw_idx` / `simplify_vw_preserve` 追加)
- `src/geo/2d/contains.mbt` (ContainsProperly 追加)
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⏳ → ✅ に更新

## 非スコープ

- pairwise predicate を `Self × Other` のトレイトとして表現する設計詳細は配下サイクルの Step 3 (Design) で確定
- `Triangle::new` の入力検証 (退化三角形の扱い) はサイクル内 Design で確定

## 依存マイルストーン

- ms-15-validation-finalize (Phase 1 確定後を起点とするため)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル (1 PR 規模)

## Notes

- 移植元参照:
  - `~/proj/geo/georust-geo/geo/src/algorithm/contains.rs` 他 pairwise predicate
  - `~/proj/geo/georust-geo/geo-types/src/geometry/triangle.rs` (`new`)
  - `~/proj/geo/georust-geo/geo/src/algorithm/affine_ops/affine_transform.rs` (残メソッド)
- ⏳ 項目の網羅対象は `mbt/package/geo-mbt/api-correspondence.md` 内検索で確定する
