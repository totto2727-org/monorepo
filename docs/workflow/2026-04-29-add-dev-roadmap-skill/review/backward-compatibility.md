# Review Report: Backward Compatibility

- **Cycle:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** backward-compatibility (既存サイクル動作 / 既存 dev-workflow / shared-artifacts スキル機能への非破壊性)
- **First reviewed:** 2026-05-01
- **Last updated:** 2026-05-03
- **Final Gate:** `approved`
- **Round count:** 2
- **SC-12 baseline:** `8444fb4` (rollback 直前 HEAD = main マージ直後)

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                                                                                                  | 状態             | 検出 Round | 解消 commit     | Notes                                                                                                                                                |
| --- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ---------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major  | T0 (`git mv docs/dev-workflow/ → docs/workflow/`) と T8/T9/T10 の 3 ファイル path 置換のみで、他 32 箇所の path 参照が `docs/dev-workflow/<identifier>/` のまま残存。Specialist が新規サイクル起動時に旧パスへ書き込む経路となり SC-12 / SC-13 失敗リスク | `fixed`          | 1          | `37eb0d3` (T13) | 29 ファイル一括 sed 置換、`ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` 0 件確認済 (Round 2 で再確認)                                        |
| i-1 | Info   | `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md:93` の歴史的 path 表記 `docs/dev-workflow/<identifier>/`                                                                                                                                          | `accepted-as-is` | 1          | -               | ADR は当時の決定の記録のため、`docs/dev-workflow/` 表記を維持するのが適切 (歴史的記述として保護)                                                     |
| i-2 | Info   | Round 2 で実施された全修正 (`metadata.version` 削除 9 ファイル / コミットメッセージ例修正 / Mermaid 化 / validation-evidence 廃止) は後方互換性に影響しない                                                                                               | (整合確認のみ)   | 2          | -               | 既存サイクル `2026-04-26-add-qa-design-step` の SC-12 検証で 100% similarity rename のみ確認、内容差分 0 を維持                                      |
| i-3 | Info   | `validation-evidence/` ディレクトリ廃止 (Round 2 で削除、validation-report.md にインライン化) は外部参照を破綻させない                                                                                                                                    | (整合確認のみ)   | 2          | -               | `ggrep -rn "validation-evidence"` で残存参照 0 件、shared-artifacts 規定では「大きな証跡 (必要な場合のみ)」というオプショナル規定のため scope-out 可 |

## SC-12 検証 (主要証拠)

最終的な後方互換性検証コマンドと結果:

```bash
git diff --find-renames 8444fb4..HEAD -- \
    docs/workflow/2026-04-26-add-qa-design-step/ \
    docs/dev-workflow/2026-04-26-add-qa-design-step/
```

結果: 全 14 ファイルが `similarity index 100%` の純粋リネームのみ、内容差分 0 行。

`docs/dev-workflow/` 物理ディレクトリ自体: 不存在 (T0 で完全リネーム済)。

## Round 履歴メタ

| Round | 実行日     | reviewer instance (簡易)                          | 単独 Gate                        |
| ----- | ---------- | ------------------------------------------------- | -------------------------------- |
| 1     | 2026-05-01 | reviewer (backward-compatibility, initial)        | `needs_fix` (Major 1 件)         |
| 2     | 2026-05-03 | reviewer (backward-compatibility, post-Minor-fix) | `approved` (Major 0、新規発生 0) |

最終 Gate: `approved`。Major / Blocker 0 件、`accepted-as-is` 1 件 (Info、ADR 内歴史記述)。
