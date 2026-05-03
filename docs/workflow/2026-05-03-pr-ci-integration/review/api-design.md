# Review Report: API Design (Workflow Contract)

- **Cycle:** 2026-05-03-pr-ci-integration
- **Aspect:** api-design — ドキュメント = ワークフローの API (公開仕様) の安定性・拡張性・契約破壊
- **First reviewed:** 2026-05-03
- **Last updated:** 2026-05-03
- **Final Gate:** needs_fix
- **Round count:** 1

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                        | 状態           | 検出 Round | 解消 commit | Notes                                                                                                                                                                                                                                      |
| --- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| M-1 | Major  | 新ルールの後方互換性 / 適用境界 (旧サイクル除外) が SKILL.md 本体に明示されていない                                                                                             | pending        | 1          | -           | design.md「移行 / 切替」(L471-473) には記述があるが SKILL.md (= 真のソース) に未反映。過去 5 サイクルが「Exit Criteria 未充足」と将来 reviewer に解釈される余地あり。詳細は M-1 詳細参照                                                   |
| M-2 | Major  | `specialist-common §7` への 1 行追加が「Git ガードレール（implementer 向け必須ルール）」サブセクション配下に置かれている                                                        | pending        | 1          | -           | 追加文の意味は「全 Specialist 向けルール」だが配置位置が implementer 専用ガードレール内のため、validator/reviewer 等の他 Specialist が SC-7 検証等で gh CLI を読み取る場面で「自分には関係ない」と読み飛ばすリスク。詳細は M-2 詳細参照    |
| m-1 | Minor  | リトライ境界条件 (「最大 2 回」「3 回目で Blocker」「2 回再 push 失敗」) の文言が混在し、初心者が曖昧と感じる余地                                                               | pending        | 1          | -           | shell ループ自体は `ATTEMPT <= 2` で厳密。ただし本文 L920 / コメント L924 / L937 で「失敗回数」「リトライ試行数」「再 push 回数」が同じ意味で使われており、3 つの軸が読み手に統一されない。詳細は m-1 詳細参照                             |
| m-2 | Minor  | `progress-yaml.md` blockers 例の「2 回連続失敗 (run id ...) → リトライ上限到達」と SKILL.md「3 回目の失敗で Blocker」の文言不一致                                               | pending        | 1          | -           | 例文 (`progress-yaml.md` L61) の「2 回連続失敗」は SKILL.md L920 の「3 回目の失敗」と並べると整合しているか曖昧。「初回 + 2 回リトライ = 3 回」の総数を「2 回連続失敗」が指すのか「2 回目以降の連続失敗」を指すのか読み取りに揺らぎ        |
| m-3 | Minor  | PR description テンプレートのセクション必須 / 任意区別が部分的にしか明示されていない                                                                                            | pending        | 1          | -           | 「Notable incidents (該当があった場合のみ)」のみ任意フラグあり、Test plan は「Step 8 で完成」、Summary / Cycle artefacts / Progress checklist / CI status は暗黙必須。将来セクション追加・削除の API 進化指針が不明確。詳細は m-3 詳細参照 |
| m-4 | Minor  | roadmap 配下サイクル時の PR description への roadmap.id / milestone.id 反映指針が未定義                                                                                         | pending        | 1          | -           | `progress.yaml.roadmap` non-null のサイクルでも本プロトコルは適用されるが、PR description テンプレート (L834-881) には roadmap リンク欄がない。dev-roadmap との整合性を将来サイクルで明示する余地あり                                      |
| m-5 | Minor  | gh CLI バージョン依存箇所 (`gh pr ready` 冪等性 / `gh run rerun --failed` の挙動) に対し将来のバージョンアップで挙動変化した場合の余白記述なし                                  | pending        | 1          | -           | `gh pr ready` の冪等性は事前 `isDraft: true` 確認で守られているが、SKILL.md には「最低 gh バージョン」「冪等性が崩れた場合の代替手段」が書かれていない。設計判断として明示しておけば長期保守性が向上                                       |
| i-1 | Info   | 新セクション名「## サイクル PR と CI 連携プロトコル」は「サイクル PR」と限定しており将来「ロードマップ PR と CI 連携プロトコル」のような兄弟セクション追加余地あり (肯定的観察) | (整合確認のみ) | 1          | -           | スキル全体図 (`## ロードマップ PR と CI 連携プロトコル` 等) との並列性を保ちやすい命名。後方互換に有利                                                                                                                                     |
| i-2 | Info   | `progress.yaml.blockers[]` を schema 拡張せず自由テキストで CI failure を記録する方針は将来 `kind: ci_failure` 等の構造化に移行可能 (肯定的観察)                                | (整合確認のみ) | 1          | -           | 自由テキストフォーマットで `commit / run id / attempts` を含めるルールが progress-yaml.md L61 に明記されており、必要なら後で構造化キーへの移行が比較的低コスト。ロックインを生まない                                                       |
| i-3 | Info   | `docs(dev-workflow/<id>)` コミット scope は `docs/workflow/` 配下リネーム後も維持されており、契約整合性が保たれている (肯定的観察)                                              | (整合確認のみ) | 1          | -           | スキル名スコープ (`dev-workflow`) と成果物ディレクトリ (`docs/workflow/`) が分離されているため、ディレクトリリネーム影響を受けず安定                                                                                                       |
| i-4 | Info   | Exit Criteria への CI PASS 1 行追加は 9 ステップ統一文言で重複もなく、機械検証 (SC-3 grep) と整合 (肯定的観察)                                                                  | (整合確認のみ) | 1          | -           | 全 9 箇所同一文言で追記され、Step 6 のみ「全タスク単位コミットそれぞれ」に変形、機械的に grep 可能で、SKILL.md 内検索性も保たれている                                                                                                      |

## 詳細セクション

### M-1 詳細: 後方互換性 / 適用境界の SKILL.md 未明示

**問題:**
本サイクルは `dev-workflow` SKILL.md に新ルール 5 件を追加したが、いずれも「適用範囲は本サイクル以降」「過去サイクルには遡及適用しない」旨が SKILL.md 本体には明記されていない。

**根拠:**

- 過去 5 サイクル (`docs/workflow/2026-04-24-*` ... `2026-04-29-retro-cleanup`) は全て新ルール (Draft PR / PR 概要更新 / CI 確認 / Ready 化) なしで Step 1〜9 を完了済み
- SKILL.md L161-559 で新たに各 Step Exit Criteria に「該当ステップ完了コミットに紐付く CI が PASS している」が追加された
- 過去サイクルの完了済みコミットに紐付く CI が PASS しているか否かは現時点で機械検証されていないため、原則として現行 Exit Criteria を**形式的に**満たさない
- design.md 「運用上の考慮事項 § 移行 / 切替」(L471-473) には「本サイクル開始時点の Step 1 完了コミット `1cb5743` には Draft PR が紐付いていない可能性」「既存の他サイクル ... の遡及改修はしない」と記述あり
- ただし design.md は本サイクル限定の設計判断を残す揮発寄りドキュメントであり、将来の reviewer / Specialist が真のソースとして読むのは SKILL.md

**API 契約への影響:**

- ルール = 公開 API。過去の利用者 (= 過去サイクル) を retroactively に契約違反扱いするのはバージョニング規律違反
- 将来の holistic reviewer / Step 9 retrospective writer が過去サイクルを引き合いに出す場面で、判断軸が SKILL.md だけ読むと不明
- セッション再開プロトコル (`## 調整プロトコル ### 5. セッション再開時`) で過去サイクルを再開した場合、新ルールの遡及適用要否が判断不能

**推奨アクション:**
新セクション「## サイクル PR と CI 連携プロトコル」冒頭または「Draft PR 初期化」サブセクション直前に以下相当の 1〜2 行を追加:

```markdown
**適用範囲:** 本セクションのルールは本サイクル (2026-05-03-pr-ci-integration) で SKILL.md に追記された時点以降に**新規開始する**サイクルに適用する。それ以前に開始済み (= initialize cycle コミット済み) のサイクルへの遡及適用はしない。再開時もサイクル開始時点のルールを継続適用する。
```

これによって API 契約のバージョニング境界が真のソースに記録される。

### M-2 詳細: §7 への 1 行追加が implementer 専用ガードレール内に配置されている

**問題:**
`specialist-common/SKILL.md` §7 には「Git ガードレール（implementer 向け必須ルール）」というサブ見出しがあり、その配下リストの末尾に PR 操作の Specialist 規約が追加されている (L186-195)。追加された行はその他の Specialist (validator / reviewer / qa-analyst 等) も対象とすべきだが、見出し名から「implementer 専用」と読まれるリスク。

**根拠:**

- `specialist-common/SKILL.md` L186 `### Git ガードレール（implementer 向け必須ルール）`
- L188 `implementer が Git コミットを実行する場合、以下を遵守する。` ← この前置きにより配下のリストは「implementer のみが守るルール」と読める
- L195 (本サイクル追加分): `PR 操作 (gh pr create / gh pr edit / gh pr ready / gh run rerun) は Main が単独で実行する。Specialist は read 系 (gh pr view --json / gh run list --json / gh run view --json) のみ使用してよい。`
- 文言上は「Specialist は read 系のみ」と全 Specialist 包括だが、配置位置から「implementer に限る規約」と誤読される

**実害シナリオ:**

- Step 8 の validator が SC-7「全ステップ完了コミット CI PASS」を `gh run list --json` で計測する際、「自分は implementer ではないからこのルールは関係ない」「むしろ自分は validator なので write 系も使ってよい」と独断する余地
- Step 7 の holistic reviewer が PR description の更新トレース (SC-6) を `gh pr view` で確認する際、同様に責務範囲が曖昧

**推奨アクション:**
2 案いずれか:

1. **配置位置を変更:** 追加された 1 行を「Git ガードレール（implementer 向け必須ルール）」サブ見出しの**外**に移動し、§7 本文 (L177-184 の「Specialist が直接 Git 操作をするかどうかは役割による」直下の独立段落) に配置する
2. **見出し改名:** 「### Git ガードレール（implementer 向け必須ルール）」を「### Git / PR ガードレール (Specialist 全般共通 + implementer 専用)」のような複合見出しに改名し、PR 操作部分は「全 Specialist 共通」と前置きする

設計上は 1 のほうが既存ガードレールの責務分離を保ちやすい (implementer 専用ルールに余計なルールを混ぜないため)。

### m-1 詳細: リトライ境界条件の文言混在

**問題:**
SKILL.md の CI 失敗リトライ規約で「**最大 2 回までリトライ**」「3 回目の失敗で Blocker」「2 回再 push しても失敗継続 → Blocker」「ATTEMPT 1, 2 まで許容、3 で Blocker」という 4 つの異なる表現が混在している。shell ループは `ATTEMPT=1` 初期化で `while [ $ATTEMPT -le 2 ]` のため、「初回失敗 + ATTEMPT=1 (リトライ 1 回目) + ATTEMPT=2 (リトライ 2 回目) = 計 3 回失敗まで実行 → 3 回目失敗で Blocker」という意味として整合する。だがこの「初回失敗を含むかどうか」が文言から読み取りづらい。

**根拠:**

- SKILL.md L920 (本文): `Main は最大 2 回までリトライする。... 3 回目の失敗で Blocker 化`
- SKILL.md L924 (コメント): `ATTEMPT=1   # 1, 2 まで許容、3 で Blocker 化` (← ATTEMPT 値の話)
- SKILL.md L937 (コメント): `# 2 回再 push しても失敗継続 → Blocker 化`
- SKILL.md L918 (見出し): `#### CI 失敗時のリトライフロー (最大 2 回 → Blocker 化)`

「最大 2 回」と「3 回目」と「2 回再 push」が同じ境界を指すが、初心者には:

- 「最大 2 回までリトライ」→ 試行回数 (= 初回 + 2 = 3 回?)
- 「3 回目の失敗で Blocker」→ 失敗総数で 3 回目?
- 「2 回再 push しても失敗継続」→ re-push 数で 2 回?

の差が読み取れない。

**API 契約への影響:**

- 「2 回リトライしたが 3 回目を試そうとしている」状態は許容されるか? shell コードでは ATTEMPT=2 のループ body で実行され、その内側の watch 完了で結果が出てから loop を抜ける。すなわちループ body 中は「3 回目の試行を実行中」=「許容」と読める
- ただし文言上は「3 回目の失敗で Blocker」とあり、watch 結果が出る前 (= 実行中) は失敗確定していないため Blocker ではない、と読む人と「3 回目の試行を始めた瞬間に Blocker」と読む人で分かれる余地

**推奨アクション:**
リトライ境界の意味論を 1 文で固定する補足を追加:

```markdown
**リトライ回数の数え方:**

- **初回 CI 失敗** = ATTEMPT=0 相当 (リトライではない)
- **リトライ 1 回目** = ATTEMPT=1 (修正 + 新 commit + push) → 失敗なら継続
- **リトライ 2 回目** = ATTEMPT=2 (修正 + 新 commit + push) → 失敗なら Blocker
- 失敗総数 (初回 + リトライ) = 3 回で Blocker 化。「2 回までリトライ」「3 回目の失敗」は同じ境界を指す
```

これにより「進行中状態」「再 push 数」「失敗総数」の混乱が解消する。

### m-3 詳細: PR description テンプレートのセクション必須/任意区別

**問題:**
PR description テンプレート (SKILL.md L834-881) は 6 セクション (Summary / Cycle artefacts / Progress checklist / CI status / Test plan / Notable incidents) で構成される。明示的に必須/任意の区別があるのは:

- Notable incidents → 「該当があった場合のみ」と明記
- Test plan → 「Step 8 で完成」と進行度依存

残り (Summary / Cycle artefacts / Progress checklist / CI status) は暗黙必須と読めるが、明文化されていない。

**API 契約への影響:**

- 将来「セクションを 1 つ追加」する別サイクルが、過去サイクルの PR description と差分が出る場合の取り扱い指針なし
- 将来「セクションを廃止」する場合、過去 PR description を更新すべきかが不明
- 「現在の PR description が SC-2 grep 検証 (PR description 更新の確認) を満たすか」が、必須セクション抜けで判定揺らぐ

**推奨アクション:**
テンプレート冒頭に必須/任意マーカーを 1 行追加:

```markdown
**セクション必須度:**

- Summary / Cycle artefacts / Progress checklist / CI status → **必須** (毎ステップ完了時に存在)
- Test plan → Step 8 完了時から必須
- Notable incidents → 該当があった場合のみ任意

**セクション追加・削除のルール:** 将来の dev-workflow 改修サイクルで本テンプレートを変更する場合、過去サイクル PR description は遡及更新せず、改修コミット以降の新規サイクルから新テンプレートを適用する。
```

これにより PR description が外部公開ビューとしての API 安定性を保てる。

## Round 履歴メタ

| Round | 実行日     | reviewer instance              | 単独 Gate |
| ----- | ---------- | ------------------------------ | --------- |
| 1     | 2026-05-03 | reviewer (api-design, initial) | needs_fix |

最終 Gate: `needs_fix`。Major / Blocker 2 件 (M-1 / M-2)、Minor 5 件 (m-1〜m-5)、Info 4 件 (i-1〜i-4)、`accepted-as-is` 0 件。
