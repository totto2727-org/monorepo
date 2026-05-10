# Milestone: API Surface Review + v0.2.0 Release Prep

- **Milestone ID:** ms-34-release-v02
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

Phase 2 全マイルストーン完了後の API 整合性確認と v0.2.0 リリース準備を行う。Phase 1 の ms-15 と同位置だが、対象機能が大幅に増えているため独立マイルストーンとして扱う。

## 到達点 (定性)

- `mbt/package/geo-mbt/api-correspondence.md` が Phase 2 全機能を反映して全行 ✅ または ⛔ に整理される (⏳ が残らない、または残る場合は Phase 3 として明示される)
- `mbt/package/geo-mbt/CLAUDE.md` の Scope / Project Structure / Commands が最新状態に更新される
- `mbt/package/geo-mbt/README.mbt.md` が Phase 2 主要 API のサンプルコードを含む
- `moon.mod.json` の version が `0.2.0` に上がる
- `vp run --filter @totto2727/geo-mbt check` および `vp run --filter @totto2727/geo-mbt test` が PASS する
- 全 module 横断の API 命名整合性が確認される (例: `triangulate_*` 系の命名規則、metric space 系の命名規則)
- `git log` 上で Phase 2 各マイルストーンの完了コミット (または PR マージ) が確認できる

## スコープ

- `mbt/package/geo-mbt/api-correspondence.md` 全面更新
- `mbt/package/geo-mbt/CLAUDE.md` 全面更新
- `mbt/package/geo-mbt/README.mbt.md` 拡充
- `mbt/package/geo-mbt/moon.mod.json` の version bump
- 各 `moon.pkg.json` のエクスポート整理 (新規 module 追加分)

## 非スコープ

- 0.2.0 タグ付け / リリースノート公開 (Phase 2 完了後の運用)
- crates.io 相当の公開操作

## 依存マイルストーン

- Phase 2 全アルゴリズム系マイルストーンの完了 (ms-16〜ms-33 のうち実装系すべて)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- Phase 1 の ms-15 と同様に「最終整合性確認」の意味も持ち、Phase 2 各マイルストーン間の不整合があれば修正コミットを起こす権限を持つ
- Phase 3 (Triangulation 派生 / 並列実装 / fuzz テスト本格化) を起こすかどうかは本マイルストーンで判断する
