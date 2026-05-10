# Milestone: Robust Predicates (orient2d/incircle) + Kernel

- **Milestone ID:** ms-05-robust-kernels
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

`robust` クレート (Shewchuk の堅牢述語) のうち 2D で必須な `orient2d` および `incircle` を MoonBit に移植し、`geo` 内 `kernels` モジュールが提供する `Orientation` enum (`Clockwise` / `CounterClockwise` / `Collinear`) と `Kernel::orient2d` 相当の API を整える。後続の凸包・包含・スイープ系アルゴリズムが共通基盤として利用する。

## 到達点 (定性)

- `src/robust/orient2d.mbt` に `orient2d(pa: Coord, pb: Coord, pc: Coord) -> Double` 相当 (符号付き面積、Shewchuk アルゴリズム) が実装される
- `src/robust/incircle.mbt` に `incircle(pa, pb, pc, pd) -> Double` 相当が実装される
- `src/geo/2d/kernel.mbt` に `Orientation` enum と `orient(p, q, r) -> Orientation` (Clockwise / CounterClockwise / Collinear) が実装される
- 既存 `mbt/package/geo/src/util/robust/` の実装を参考にしつつ、`geo-mbt` 内で完結する形に再実装する (依存をパッケージ間で持たない)
- Rust 版 `robust/src/lib.rs` および `geo/src/algorithm/kernels/mod.rs` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/robust/{orient2d,incircle}.mbt` + `_test.mbt`
- `src/robust/moon.pkg.json`
- `src/geo/2d/kernel.mbt` + `_test.mbt`
- 既存 `mbt/package/geo/src/util/robust/` のロジックを参考 (流用ではなく再確認)

## 非スコープ

- 3D 用 `orient3d` / `insphere` — ロードマップ非スコープ
- 階層的 fp 演算 (extended-precision arithmetic) のフルポート — Shewchuk の adaptive predicates のうち本ロードマップで必要な精度のみ実装

## 依存マイルストーン

- ms-02-primitives: `Coord` 型を入力に取るため

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/robust/src/lib.rs` (主要関数), `~/proj/geo/georust-geo/geo/src/algorithm/kernels/mod.rs`, `~/proj/geo/georust-geo/geo/src/algorithm/kernels/robust.rs`
- 浮動小数点演算精度に最も敏感な箇所 — Rust 版テスト (特に退化ケース、共線ケース) を完全に移植して回帰検出可能にする
- 既存 `mbt/package/geo/src/util/robust/orient2d.mbt` は良いリファレンス
