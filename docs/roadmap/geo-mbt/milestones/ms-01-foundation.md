# Milestone: Foundation — Package Skeleton + Coord Type

- **Milestone ID:** ms-01-foundation
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

`mbt/package/geo-mbt/` の MoonBit パッケージ雛形を整備し、最下層の `Coord` 型 (2D, `f64` 固定) と関連する 4 則演算 (`add` / `sub` / `neg` / `mul` / `div` / `dot` / `cross`) を完備する。後続 14 マイルストーンの共通基盤を成立させる。

## 到達点 (定性)

- `mbt/package/geo-mbt/` 配下に `moon.mod.json` / `package.json` / `vite.config.ts` / `src/geo/2d/` / `src/robust/` のディレクトリ構造が成立する
- パッケージ名 `@totto2727/geo-mbt`、moon module 名 `totto2727/geo-mbt` で `vp run --filter @totto2727/geo-mbt check` および `vp run --filter @totto2727/geo-mbt test` が PASS する (テストが空でも PASS と認める)
- `Coord` 型 (フィールド `x: Double`, `y: Double`) が `src/geo/2d/type/coord.mbt` に実装され、Rust 版 `geo-types/src/geometry/coord.rs` の単項・二項演算 (`Add` / `Sub` / `Neg` / `Mul<T>` / `Div<T>` / `Zero` 相当) が MoonBit メソッド (`coord.add(other)`, `coord.sub(other)`, `coord.neg()`, `coord.mul(scalar)`, `coord.div(scalar)`, `Coord::zero()`) として提供される
- Rust 版 `coord.rs` の `#[cfg(test)]` テストブロック (`test_coord_add` 等) が MoonBit `coord_test.mbt` に同等内容で移植され PASS する
- API 命名規則 (関数 vs メソッド、`*_of` サフィックスの可否、Rust trait 名の MoonBit 表現) が `docs/workflow/<identifier>/design.md` で確定し、後続マイルストーンの前提として参照可能になる
- MoonBit `Double` の NaN ガード方針 (Rust 版は型レベルで `T: CoordNum` のため NaN を排除しないが、本 port での扱い) が `design.md` で確定する

## スコープ

- `mbt/package/geo-mbt/moon.mod.json` (deps: `moonbitlang/x`)
- `mbt/package/geo-mbt/package.json` (`vite-plus` catalog)
- `mbt/package/geo-mbt/vite.config.ts` (build/check/fix/test タスク)
- `mbt/package/geo-mbt/CLAUDE.md` (パッケージ概要、コマンド、ワークフロー)
- `mbt/package/geo-mbt/README.md` / `README.mbt.md`
- `mbt/package/geo-mbt/src/geo/2d/type/coord.mbt`
- `mbt/package/geo-mbt/src/geo/2d/type/coord_test.mbt`
- `mbt/package/geo-mbt/src/geo/2d/type/moon.pkg.json`

## 非スコープ

- 他のジオメトリ型 (Point / Line / LineString 等) — ms-02 の責務
- 堅牢述語 (`orient2d` 等) — ms-05 の責務
- 反復系 (CoordsIter 等) — ms-03 の責務
- アルゴリズム (Area / BoundingRect 等) — ms-04 以降

## 依存マイルストーン

- (なし) — 本マイルストーンはロードマップの起点

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時 (Step 2): 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル (1 PR 規模)

## Notes

- 移植元参照: `~/proj/geo/georust-geo/geo-types/src/geometry/coord.rs`、`~/proj/geo/georust-geo/geo-types/src/lib.rs` (CoordNum / CoordFloat trait 定義)
- 既存 `mbt/package/geo/src/type/coord.mbt` および `xy.mbt` を参考に MoonBit 慣習に沿った命名を採用するが、ジェネリクス・トレイトは初期は導入しない (具体型 `Coord` を直接公開)
- 命名規則決定: Rust trait 名と同名の関数 (例: `area`, `centroid`, `bounding_rect`) を提供する方針を第 1 候補とする (MoonBit のメソッド `polygon.area()` 形式で呼び出せるよう)
