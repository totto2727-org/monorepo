# Milestone: Affine Ops — Translate/Rotate/Scale/Skew/AffineTransform

- **Milestone ID:** ms-10-affine
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリのアフィン変換 (平行移動 / 回転 / 拡縮 / 剪断 / 合成) を `AffineTransform` 構造体と関数 API として MoonBit に移植する。

## 到達点 (定性)

- `src/geo/2d/affine_transform.mbt` に `AffineTransform` 構造体 (3×3 行列の上 2 行 = 6 要素表現) と合成 (`compose`)、適用 (`apply`)、逆行列 (`inverse`)、各種コンストラクタ (`identity`, `translate`, `scale`, `rotate`, `skew`) が実装される
- `src/geo/2d/translate.mbt`, `rotate.mbt`, `scale.mbt`, `skew.mbt` に各演算の高レベル関数 (`translate(geometry, dx, dy) -> Geometry` 等) が実装される
- 中心点指定の `rotate_around` / `scale_around` 等のバリエーションも提供
- Rust 版 `affine_ops.rs`, `translate.rs`, `rotate.rs`, `scale.rs`, `skew.rs` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/affine_transform.mbt` + `_test.mbt`
- `src/geo/2d/{translate,rotate,scale,skew}.mbt` + `_test.mbt`

## 非スコープ

- PROJ ベースの座標系変換 (`Transform`) — ロードマップ非スコープ
- 角度単位変換 (`ToDegrees` / `ToRadians`) — 余裕があれば追加。なければ将来検討

## 依存マイルストーン

- ms-04-bounding-area: 中心点指定の rotate / scale で `bounding_rect` 由来の中心や `centroid` を利用 (centroid は ms-09 だが ms-09 は ms-04 + ms-07 に依存)。アフィン演算自体は ms-04 完了後に着手可能。`rotate_around_centroid` のような派生は ms-09 完了後に追加することも可

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/{affine_ops,translate,rotate,scale,skew}.rs`
- Rust 版は `AffineOps` trait で全ジオメトリ型に impl。MoonBit ではジオメトリ型をパターンマッチで分岐する `apply_affine(geometry, transform) -> Geometry` 形式
