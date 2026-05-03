# Review Report: test-quality

- **Cycle:** 2026-05-03-pr-ci-integration
- **Aspect:** test-quality (qa-design.md / qa-flow.md / Step 8 Validator が実行する検証コマンドの再現性と網羅性)
- **First reviewed:** 2026-05-03
- **Last updated:** 2026-05-03
- **Final Gate:** needs_fix
- **Round count:** 1

## サマリ

- **Blocker:** 0 件
- **Major:** 8 件 (M-1〜M-8) — Step 8 Validator が false negative / false positive を出す根拠を伴う
- **Minor:** 5 件 (m-1〜m-5)
- **Info:** 8 件 (i-1〜i-8、整合確認のみ)
- **Final Gate:** needs_fix

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                                           | 状態    | 検出 Round | 解消 commit |
| --- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------- | ----------- |
| M-1 | Major  | TC-007 の `awk '/^## サイクル PR と CI 連携プロトコル/,/^## /'` は範囲アドレスの仕様上、開始行自身が終端 `^## ` にマッチして 1 行で打ち切られる。実機 `wc -l` が 1。flag sentinel 形式に修正必要。 | pending | 1          | -           |
| M-2 | Major  | TC-011 の `awk '/^### blockers/...'` は `progress-yaml.md` 実見出し (バッククォート付き) `` ### `blockers` `` にマッチしない。実機 grep exit code 1。                                              | pending | 1          | -           |
| M-3 | Major  | TC-008 にも同種 awk 範囲アドレス欠陥が潜在。`gawk` バージョンや見出しレベル変更で容易に壊れる。flag/sed 統一推奨。                                                                                 | pending | 1          | -           |
| M-4 | Major  | TC-007 の判定基準で「H2 配下に H3 サブセクション本文を含めるか」が曖昧。SC-3「Blocker と接続」の判定が崩れる原因。                                                                                 | pending | 1          | -           |
| M-5 | Major  | TC-014 の `grep -cE` のパイプ式が省略され、Validator が SKILL.md 内テンプレート部 (6 件ヒット) を誤って grep 対象にする恐れ。                                                                      | pending | 1          | -           |
| M-6 | Major  | TC-015 の event 名 (`renamed`/`edited`/`body_changed`) を「Validator が確定」と先送り。観測可能性違反。本サイクルで実機特定し固定値に置換すべき。                                                  | pending | 1          | -           |
| M-7 | Major  | TC-022 の `grep -cE 'if \[ "\$IS_DRAFT" = "true" \]'` は文字列マッチが脆弱。design.md 擬似コード書式変更で容易に壊れる。緩和またはリンク参照推奨。                                                 | pending | 1          | -           |
| M-8 | Major  | TC-019 (Blocker 記録) は `skip [該当ケースなし]` 明示。TC-018 (リトライ 2 回以下) は failure 0 件で pass / skip の二重解釈。明文化必要。                                                           | pending | 1          | -           |
| m-1 | Minor  | qa-design.md L57 横長表 + 1 セルに複数 grep 詰め込み。`validation-commands.sh` 別添 or TC-NNN ごと箇条書き化を推奨。                                                                               | pending | 1          | -           |
| m-2 | Minor  | TC-007 の awk 範囲アドレス挙動の補注 1 行追加で Validator 修正版に到達容易。                                                                                                                       | pending | 1          | -           |
| m-3 | Minor  | TC-009 の grep を 3 個別に分けると診断容易性向上。                                                                                                                                                 | pending | 1          | -           |
| m-4 | Minor  | TC-018 「failure 連続数」の数え方の jq one-liner 例追加で解釈ぶれ抑制。                                                                                                                            | pending | 1          | -           |
| m-5 | Minor  | TC-IMPL-NNN 空セクションに「本サイクルでは追記対象なし」明示推奨。                                                                                                                                 | pending | 1          | -           |
| i-1 | Info   | カバレッジ表 (L106-115) は SC-1〜SC-8 全件カバー、複雑 SC に複数件紐付き。                                                                                                                         | (整合)  | 1          | -           |
| i-2 | Info   | 2 軸 enum 整合: 全 22 TC が `automated × {assertion(12), scenario(10)}`。禁止組み合わせなし。                                                                                                      | (整合)  | 1          | -           |
| i-3 | Info   | qa-flow.md Mermaid 6 セクションは SC-1〜SC-8 網羅、各葉に TC-ID または `skip` 付与。                                                                                                               | (整合)  | 1          | -           |
| i-4 | Info   | mock 濫用なし。SC-5/6/7/8 動的検証は実 PR / 実 CI run / 実 git log 観測。                                                                                                                          | (整合)  | 1          | -           |
| i-5 | Info   | TC-009 補正後の 3 見出し (`役割定義` / `ステップ詳細` / `ステップ完了時のコミット規約`) はすべて実 SKILL.md に存在 (grep `3`)。T7 の補正は妥当。                                                   | (整合)  | 1          | -           |
| i-6 | Info   | TC-IMPL-NNN は空テーブル + プレースホルダ文で reference 仕様に整合。本サイクルで TC-IMPL 不要は妥当。                                                                                              | (整合)  | 1          | -           |
| i-7 | Info   | SC-7 (CI 最終 PASS) の TC-017 判定基準は `--commit <sha>` 最新 attempt 取得で正しく表現。`gh run list` の `attempt` フィールド存在確認済。                                                         | (整合)  | 1          | -           |
| i-8 | Info   | SC-8 (Ready 化タイミング) の TC-021 は `gh api .../timeline` から `event == "ready_for_review"` 抽出 + ISO8601 比較で正しく表現。`readyForReviewAt` 不在は `gh-cli.md` F-4 で裏取り済。            | (整合)  | 1          | -           |

## 詳細セクション

### M-1 詳細: TC-007 の awk 範囲アドレス欠陥

GNU awk / BSD awk の範囲アドレス `/start/,/end/` は **開始行自身が終端パターンにもマッチした場合、1 行で打ち切る** 仕様。`^## サイクル PR と CI 連携プロトコル` は `^## ` にマッチするため 1 行で終わる。

**修正案:**

```bash
gawk '/^## サイクル PR と CI 連携プロトコル/{flag=1; next} /^## /{flag=0} flag' SKILL.md
```

### M-2 詳細: TC-011 の awk アンカー不一致

`progress-yaml.md` 実見出しはバッククォート付き `` ### `blockers` ``。修正案:

```bash
gawk '/^### `blockers`/{flag=1; next} /^### /{flag=0} flag' progress-yaml.md
```

### M-6 詳細: TC-015 の event 名先送り

GitHub PR の description (body) 編集は REST timeline API の event には**現れない** (`renamed` event は title 変更のみ)。description 変更検出は (a) `PATCH /pulls/{n}` の `updated_at` 変化、または (b) スナップショット比較に依存。

**推奨アクション:** qa-analyst が本サイクル PR #95 で `gh api .../timeline --paginate | jq '.[] | .event' | sort -u` を 1 度実行し、実観測される event 名を qa-design.md L73 に固定値で記載するか、TC-015 を `gh api repos/.../issues/<num> --jq '.updated_at != .created_at'` 等に書き換える。

## Round 履歴メタ

| Round | 実行日     | reviewer instance                        | 単独 Gate |
| ----- | ---------- | ---------------------------------------- | --------- |
| 1     | 2026-05-03 | reviewer (test-quality, initial Round 1) | needs_fix |
