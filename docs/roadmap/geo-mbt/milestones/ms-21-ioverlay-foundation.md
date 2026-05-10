# Milestone: i_overlay Foundation (deps + segments + grid layout)

- **Milestone ID:** ms-21-ioverlay-foundation
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

Rust `i_overlay` クレート相当の汎用 BooleanOps エンジンを Pure MoonBit で port するための土台層を作る。Phase 2 で最大規模のマイルストーン群 (ms-21〜ms-23) の最初のステップ。

`i_overlay` は ~19,400 LOC の crate で、4 つの依存 crate (`i_float` / `i_shape` / `i_tree` / `i_key_sort`) を持つ。本マイルストーンではそれら依存クレートと、segment 表現 + segment splitting (cross_solver) + grid layout を MoonBit に持ち込む。

## 到達点 (定性)

- `src/i_float/` に upstream `i_float` 相当 (固定小数点 / 整数座標 / FloatPointAdapter) が動作する
- `src/i_shape/` に upstream `i_shape` 相当 (整数 polygon / contour) が動作する
- `src/i_tree/` に upstream `i_tree` 相当 (sweep status BST) が動作する
- `src/i_key_sort/` に upstream `i_key_sort` 相当 (key-based bucket sort) が動作する
- `src/i_overlay/segm/` に segment 表現 + 関連プリミティブが揃う
- `src/i_overlay/split/` に cross_solver + grid_layout + segment splitting が動作する
- 単体テスト (各 module 内 doctest) と cross-module 統合テストが PASS する

## スコープ

- `src/i_float/` 全体 (upstream `i_float` の `~/proj/geo/i_overlay/iFloat/src/` 相当 — ただしリポジトリ内の独立 crate を別途確認)
- `src/i_shape/` 全体
- `src/i_tree/` 全体
- `src/i_key_sort/` 全体
- `src/i_overlay/segm/` (`Segment`, `VectorEdge`, segment building helpers)
- `src/i_overlay/split/` (`SplitSolver`, `cross_solver`, `grid_layout`)
- 各 `*_test.mbt.md` + 必要な bench

## 非スコープ

- Overlay graph (ms-22 の責務)
- 公開 BooleanOps API (ms-23 の責務)
- mesh / stroke / offset (ms-24 の責務)
- string clipping (ms-23 の責務)
- Rust/WASM bridge アプローチ — ロードマップ上の正準アプローチは pure MoonBit port

## 依存マイルストーン

- ms-19-sweep-infrastructure (sweep 抽象を一部再利用する可能性)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

3 サイクル (依存 crate × 1 + segm/split × 2)

## Notes

- 移植元:
  - `~/proj/geo/i_overlay/iOverlay/src/segm/`
  - `~/proj/geo/i_overlay/iOverlay/src/split/`
  - `~/proj/geo/i_overlay/i_float/src/` (要確認: クレート構造)
  - `~/proj/geo/i_overlay/i_shape/src/`
  - `~/proj/geo/i_overlay/i_tree/src/`
  - `~/proj/geo/i_overlay/i_key_sort/src/`
- **代替アプローチ (記録のみ)**: Rust `i_overlay` を WASM 化して MoonBit から FFI 経由で呼ぶ案。技術的には可能だが、(a) MoonBit native / wasm / JS target 間で扱いが分かれる、(b) build pipeline が複雑になる、(c) pure MoonBit library として配布しづらい、(d) geometry type conversion の境界コストが大きい、ためロードマップ上の正準アプローチとしては採用しない。実測・配布要件次第で配下サイクル Step 3 (Design) で再検討は可能
- `i_overlay` は整数座標で動作する。MoonBit 上の整数型と precision 設定方針はサイクル Step 3 で確定
