# Research Note: reviewer-scope-merge

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Topic:** reviewer-scope-merge — `specialist-reviewer` / `specialist-self-reviewer` の責務マッピングと統合設計の余地
- **Researcher:** researcher (single instance, parallel-safe)
- **Created at:** 2026-04-29T00:00:00Z
- **Scope:**
  - 対象: 現状 Step 7 `specialist-self-reviewer` と Step 8 `specialist-reviewer` の責務・入出力・ライフサイクル・Gate 形式の比較整理、および統合後の reviewer に追加すべき責務（旧 Self-Review 役割）の設計余地洗い出し
  - 対象外: External Review 観点（security / performance / readability / test-quality / api-design）の再定義、新 Specialist の追加、フェーズ概念の再導入、`progress.yaml` のスキーマ詳細決定（design.md の領域）

## 調査対象

本サイクル（`2026-04-29-integrate-self-review-into-external`）は dev-workflow プラグインから Step 7 (Self-Review) を削除し、その責務を Step 8 (External Review) の `reviewer` 群に統合する自己改修である（intent-spec.md L22–L24）。本 Research Note は、Step 3 (Design) で以下を判断するための事実基盤と設計余地を提供する:

1. 統合後の `reviewer` がどのような新責務（旧 Self-Review 役割）を引き受けるか
2. 「全体整合性チェック」を新観点として独立追加するか / 既存観点に分散吸収するか
3. 深刻度ラベル（旧 Self-Review = High/Medium/Low、旧 External Review = Blocker/Major/Minor）をどちらに寄せるか
4. Round 1 で High/Blocker 検出 → Step 6 再活性化、というループ運用ルール（旧 Self-Review の 3 周ループ知見の移植先）
5. agent description / Do NOT use for の更新案（frontmatter 250 文字程度の制約）

intent-spec.md「未解決事項」L189–L201 で列挙された design.md 確定事項のうち、責務マッピング・深刻度ラベル統合・ループ運用の 3 点に直接寄与する。

## 発見事項

### F1. specialist-self-reviewer の主要責務（削除対象）

`plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md` (L19–L98) より:

- **担当ステップ:** Step 7 (Self-Review)
- **並列度:** 1 名（全体整合性が必要なので単一インスタンス、L32）
- **成果物:** `docs/dev-workflow/<identifier>/self-review-report.md`（単一ファイル）
- **焦点（L38–L46）:**
  - Design Document の設計判断に違反していないか
  - Intent Spec の成功基準を満たす見込みがあるか（Validation 前の見立て）
  - 明白な bug（null 参照、エッジケース漏れ、型の誤用など）
  - Task Plan 内で発見された未対応事項
  - テスト網羅性の明らかな不足
  - 型安全性・エラーハンドリングの実装品質
- **明示的なスコープ排除（L47）:** 外部観点（security / performance / readability / etc.）は Step 8 `specialist-reviewer` の領域。Self-Review は「実装チーム内の最終チェック」として全体整合性を見る
- **入力（L51–L56）:** 全 implementer の Git コミット履歴と diff、`design.md`、`intent-spec.md`、`task-plan.md`
- **深刻度ラベル（L67–L70, references/self-review-report.md L44–L49）:**
  - **High:** 修正必須。これを残したまま Step 8 に進めない
  - **Medium:** 修正推奨。Retrospective で扱うか、Step 8 で判断
  - **Low:** 記録のみ（提案レベル）
- **Gate 種別:** Main 判定（dev-workflow/SKILL.md L423）。High 残あれば Step 6 へ差し戻し
- **失敗モード（L84–L90）:**
  - High 指摘が 3 周以上ループ → Step 3 への設計回帰を提案
  - 自分の指摘が実装意図と矛盾 → セカンドオピニオン用に追加 self-reviewer 起動
  - Task Plan 内の未実装タスクを発見 → High 指摘として記録
- **整合性チェック項目（references/self-review-report.md L51–L55）:** Intent Spec 成功基準充足見込み（満たす見込みあり / 懸念あり / 未達の恐れあり）、Design Document 整合（準拠 / 部分的に逸脱 / 大きく逸脱）
- **修正ラウンド履歴（references L57–L62）:** Round 1〜N の High 件数推移を記録する欄が template / reference に標準化されている

### F2. specialist-reviewer の主要責務（現状）

`plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` (L20–L131) より:

- **担当ステップ:** Step 8 (External Review)
- **並列度:** 高（観点ごとに並列、1 Specialist = 1 観点、L48）
- **成果物:** `docs/dev-workflow/<identifier>/review/<aspect>.md`（観点ごとに 1 ファイル）
- **観点例（L40–L46）:** `security` / `performance` / `readability` / `test-quality` / `api-design` / プロジェクト固有
- **入力（L51–L57）:** 担当する単一のレビュー観点と `<aspect>` 名、全 Git コミットと diff、`design.md` の関連部分、`intent-spec.md`
- **深刻度ラベル（L65–L68, references/review-report.md L44–L48）:**
  - **Blocker:** これを残したまま完了にできない（リリース阻害レベル）
  - **Major:** 修正すべき。ユーザー承認前に議論が必要
  - **Minor:** 記録のみ（改善提案レベル）
- **Gate 種別:** ユーザー承認必須（dev-workflow/SKILL.md L498）。Blocker 0 件確認 + Minor 扱い方針
- **観点別評価項目（L81–L113）:**
  - security: 認証認可網羅、入力バリデーション、秘匿情報、依存脆弱性
  - performance: 計算量、I/O パターン、メモリ、並行性
  - readability: 命名、責務分離、コメント、型表現
  - test-quality: エッジケース網羅、mock 適切性、テスト独立性
  - api-design: 後方互換性、契約明確さ、エラーモデル一貫性、命名拡張性、ゲート契約一致
- **他 reviewer との矛盾記録（L122 / references L104–L116）:** 矛盾対象 / 相手の主張 / 自分の立場 / 根拠の違い / 推奨の 5 項目を記録する標準フォーマットあり
- **失敗モード（L117–L122）:**
  - 担当観点の範囲外に問題が波及 → Main に追加観点 reviewer の並列起動を促す
  - 他 reviewer との矛盾 → 両者の根拠をレポートに記録、Main に判断を仰ぐ
  - 観点不足の発見 → Main に追加 reviewer を並列起動してもらう

### F3. 責務・運用の比較表（重複点と差異点）

| 項目 | self-reviewer (Step 7) | reviewer (Step 8) | 差分 |
| --- | --- | --- | --- |
| 並列度 | 1 名（単一） | N 並列（観点ごと） | **構造的差異**：単一 vs 並列 |
| 観点軸 | 観点なし（全体俯瞰） | 1 観点固定 | **直交軸**：横串 vs 縦串 |
| 成果物粒度 | 1 ファイル統合 | 観点ごと 1 ファイル | self-reviewer の方が粒度大 |
| 深刻度ラベル | High / Medium / Low | Blocker / Major / Minor | **用語不統一** |
| Gate 種別 | Main 判定 | ユーザー承認必須 | reviewer の方が承認が重い |
| 入力 | 全 diff + design + intent + task-plan | 全 diff + design + intent | task-plan 参照は self-reviewer のみ |
| 整合性チェック | Intent Spec 成功基準充足見込み（満たす/懸念/未達）、Design 整合（準拠/部分逸脱/大逸脱）、修正ラウンド履歴 | aspect-specific evaluation、cross-review consistency 記録 | **self-reviewer 固有**：成功基準見込みの三段評価 |
| 重複項目（観点として両者がカバー） | テスト網羅性 | test-quality（同じ） | 重複 |
| 重複項目 | Design 整合性 | api-design 観点 + 他観点本文での「Design 違反」言及 | 部分重複 |
| 重複項目 | 明白な bug（null/型/エッジケース） | readability + test-quality + 各観点で発見されうる | 部分重複（観点ごとに分散） |
| self-reviewer 固有 | 全体俯瞰、Task Plan 完了確認、Intent Spec 成功基準充足見込み、修正ラウンド履歴 | （該当なし） | **吸収すべき責務の核** |
| reviewer 固有 | （該当なし） | security / performance（self-reviewer は明示除外）、観点固有評価項目、cross-review consistency | self-reviewer 廃止後も維持 |
| 失敗時の追加起動 | セカンドオピニオン用に追加 self-reviewer 起動 | 観点不足発見時に追加 reviewer 並列起動 | 並列起動ポリシーは reviewer のみネイティブ対応 |
| ループ上限 | 3 周以上で Step 3 へロールバック検討（dev-workflow/SKILL.md L464） | （明示記述なし。Step 8 失敗時の挙動は L500–L505、観点追加・矛盾解消が中心） | **self-reviewer 固有のナレッジ**で移植先要決定 |
| Gate 名（Exit Criteria） | High 0 件で passed/failed | Blocker 0 件で approved/needs_fix/blocked | **3 値 vs 2 値**の差 |
| Status 欄 | open / fixed / wontfix_with_reason（指摘単位） | 暗黙（指摘単位の status 欄なし） | self-reviewer 固有のフォロー仕組み |

### F4. dev-workflow/SKILL.md の Step 6 ↔ Step 7 ループ構造

dev-workflow/SKILL.md L437–L464「Step 6 ↔ Step 7 ループ」のシーケンス:

```
[Step 6 活性化] implementer A1..AN 並列
    ↓ Exit Criteria 満たす
[Step 6 完了] implementer 役割終了
    ↓
[Step 7 活性化] self-reviewer B1 起動
    ↓
    B1 が指摘生成 ─────┐
    │                   │
   (High 0)        High 指摘あり
    │                   │
Step 8 へ        [Step 6 再活性化]
                 新規 implementer C1..Ck 起動 (B1 は Step 7 継続維持)
                 C1..Ck が修正 diff 返却
                     ↓
                 [Step 6 再完了] C1..Ck 役割終了
                     ↓
                 既存 B1 が再レビュー
                     ↓
                 High 0 確認 → Step 8 へ (B1 役割終了)
```

**ループ上限の目安（L464）:** 同一 Self-Review Report の High 指摘で 3 周以上ループする場合、設計レベルの問題を疑い Step 3 へロールバックを検討。

統合後はこのループが「Step 6 ↔ Step 7 (External Review)」になるが、`reviewer` は N 並列のため、ループの主体は「**全 reviewer の合意で High/Blocker 0 件**」で判断される必要がある。再活性化後は新規 reviewer 起動（Step を抜ける時点で前 reviewer 役割終了のため）。

### F5. 直前サイクル retrospective の決定的根拠

`docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` より:

- 「課題 / ループ回数の分析」L31–L40:

| ループ | 回数 | 根本原因 |
| --- | --- | --- |
| Step 5 ↔ Step 6 (Self-Review) | Round 2 | Medium 4 件のみ。**設計時の委譲チェックリスト不足**（軽微） |
| Step 5 ↔ Step 7 (External Review) | Round 3 (13/16 件) | Major 13 件は readability / api-design / security / test-quality 観点で存在し、**Self-Review の 1 観点的視点では検出困難**だった |

→ **Self-Review の費用対効果が低い**ことが定量的に確認されている（4 件 < 13 件、observation 観点での網羅性が観点別 reviewer 群に劣る）。

- 「次回改善案 → プロセス改善」L62 第 3 項目:
  > 「External Review を Step 6 (Self-Review) と同時または先行起動する: 5 観点別 reviewer を Self-Review 時点で並列起動し、Self-Review は『自前視点の追加観点』に絞る。これで Step 5 ↔ Step 7 の Round 3 (13/16 件修正) を Step 5 内の初回で吸収でき、再活性化コストを削減できる。」

ユーザーはこの改善案を一歩進めて Self-Review 自体を廃止し責務を External Review に吸収する判断を下した（intent-spec.md L18）。

- 「再利用可能な知見」L94:
  > 「External Review の 5 観点並列起動（security / performance / readability / test-quality / api-design）は、コードレビューだけでなく Markdown 成果物でも効果がある。」

→ Self-Review が独立ステップでなくとも、観点並列で網羅できる実証済み。ただし **Self-Review が担っていた「全体俯瞰」「Task Plan 完了確認」「Intent Spec 成功基準充足見込み」を観点別 reviewer のどこかが拾う必要がある**点は別途設計が必要。

### F6. agent description / Do NOT use for の現状文字数

`plugins/dev-workflow/agents/reviewer.md` L1–L9 の description（既に存在する 1 観点 N 並列向けの description）:

- 全体: 約 250 文字（句読点込み、Do NOT use for を含む）
- 「Do NOT use for」3 項目: 複数観点の統合レビュー（self-reviewer を使う）、成功基準実測（validator）、設計妥当性検証（architect フェーズ済み前提）

統合後は **「self-reviewer を使う」言及を削除**し、代わりに「全体整合性チェック（旧 Self-Review 役割）も本観点で扱う」を本文に明記する必要がある。description 250 文字制約のため、Do NOT use for の 1 項目削除と引き換えに「全体整合性チェックを担う旨」を追加するのが現実的。

`plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の description（L3–L14）も同様の改訂が必要。intent-spec.md L165 で「frontmatter 内 250 文字程度の制約あり」と明記。

### F7. shared-artifacts への波及

- `references/review-report.md` L5「Self-Review（全体整合性）とは別層で、観点固有の深い検査を行う」L19–L23（reviewer 並列インスタンスで作成）L121「Self-Review レポート（Step 7）とは別層」と Self-Review への明示参照が複数。intent-spec.md L86–L88 で更新対象として列挙済み。
- `references/self-review-report.md` / `templates/self-review-report.md` は削除対象（intent-spec.md L31–L34）。
- `references/retrospective.md` の「Step 6 ↔ Step 7 ループ表」「self-review-report.md の参照」も更新対象（intent-spec.md L83–L85）。

## 引用元

- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md:L1-L131`
- `plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md:L1-L98`
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:L1-L229`
- `plugins/dev-workflow/agents/reviewer.md:L1-L40`
- `plugins/dev-workflow/agents/self-reviewer.md:L1-L37`
- `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md:L1-L138`
- `plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md:L1-L89`
- `plugins/dev-workflow/skills/shared-artifacts/templates/review-report.md:L1-L73`
- `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md:L1-L62`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L398-L464`（Step 7 Self-Review セクション）
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L466-L505`（Step 8 External Review セクション）
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L781-L792`（並列起動ガイドライン表）
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L819-L835`（ロールバック早見表）
- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md:L31-L40`（ループ回数分析）
- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md:L62`（次回改善案 第 3 項目）
- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md:L94`（再利用可能な知見）
- `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md:L18-L201`

## 設計への含意

### I1. 統合後 reviewer に追加すべき新責務（Self-Review 由来）

統合後の `specialist-reviewer` は、観点別深掘り（既存）に加えて以下を引き受ける必要がある:

1. **全体俯瞰（cross-cutting consistency）**: 観点を横断する整合性。各 reviewer が自観点では拾えないが「全 diff を通読すると見えてくる」問題（例: モジュール A と B で命名規則が食い違う、Task Plan の T3 が部分実装で残っている等）。
2. **Intent Spec 成功基準充足見込みの三段評価**: 「満たす見込みあり / 懸念あり / 未達の恐れあり」という Validation 前の見立て。これは F1 で確認した self-reviewer 固有の項目。
3. **Task Plan 完了判定**: TODO.md と diff を突き合わせ、未実装タスクが残っていないかの確認。
4. **明白な bug（null / 型 / エッジケース）**: 旧 Self-Review が「観点を持たない bug 検出」として機能していた領域。観点別 reviewer に分散吸収が必要。
5. **修正ラウンド履歴の記録**: Round 1 / Round 2 / ... の High（→Blocker） 件数推移。各 reviewer が個別に記録するか、Main が集約レポートを作るかは設計判断。

### I2. 「全体整合性チェック」をどう配置するか — 3 案の比較

intent-spec.md L189–L192 が要求する設計判断。以下 3 案を提示:

#### 案 A: 既存 5 観点のまま、各 reviewer 本文に「全体整合性も検出する」を追記

- **方針:** security / performance / readability / test-quality / api-design の 5 reviewer 全員が、自観点に加えて「他観点との整合性」「全体俯瞰での違和感」「Task Plan / Intent Spec への準拠」も検出するよう本文を改訂。
- **メリット:**
  - Specialist 数が増えない（5 並列のまま）
  - intent-spec.md「External Review 観点の再定義は非スコープ」(L113) との整合性が高い
  - 観点ごとの深掘りと全体俯瞰が同一インスタンスで行えるため、観点間整合性の指摘がシームレス
- **デメリット:**
  - **責務が曖昧になる**：「全体整合性は誰が一次責任か」が分散し、漏れと重複を同時に生む（旧 Self-Review が解決していた問題が部分的に戻る）
  - 5 reviewer 全員が同じことを書く可能性（cross-review consistency 記録の運用負荷増）
  - Intent Spec 成功基準充足見込みの三段評価は誰が出すのか不明瞭
- **判定:** 短期的には実装コスト最小だが、Self-Review 廃止の動機（網羅性向上）に逆行するリスクあり。

#### 案 B: 6 観点目「holistic」を追加し、1 reviewer を専任

- **方針:** `holistic` （または `consistency` / `integration`）観点を新設し、専任 reviewer を 1 名追加。役割は旧 Self-Review の責務（全体俯瞰 / Task Plan 完了 / Intent Spec 充足見込み / 明白な bug）を全継承。他 5 観点はスコープ変更なし。
- **メリット:**
  - **責務が明確**：全体整合性の一次責任者が単一インスタンスに集約され、Intent Spec 成功基準三段評価などの自然な居場所ができる
  - intent-spec.md 「成功基準 #11」（L143）「『全体整合性チェック』を吸収した旨が明記」を満たしやすい
  - 旧 Self-Review の「3 周以上ループしたら設計レベル疑い」のループ上限知見を `holistic` reviewer の固有知見として移植可能
  - Specialist 命名は `specialist-reviewer` のまま、`<aspect>` enum に `holistic` を追加するだけで済む（reviewer 数の増加が運用に与える影響は並列度の +1 のみ）
- **デメリット:**
  - 1 観点増えるため、並列起動の reviewer 数が 5 → 6 に増加（ただし Markdown 成果物では並列コストは線形のため軽微）
  - intent-spec.md「成功基準 #11」（L143）を満たすには `specialist-reviewer/SKILL.md` 本文に「全観点が整合性も見るが、特に holistic reviewer が一次責任」と書く必要があり、表現が冗長
- **判定:** **推奨案**。責務明確性と Self-Review 廃止意図の両立が取れる最もシンプルな構造。intent-spec.md 「未解決事項」L189–L192 の選択肢としても明示されている。

#### 案 C: 5 + 1（lead reviewer が観点間の整合性を統合）

- **方針:** 既存 5 観点 reviewer に加えて、5 reviewer の出力を集約して整合性レポートを書く `lead-reviewer`（または `aggregator`）を 1 体追加。lead は他 reviewer の出力を読んで整合性問題と全体俯瞰指摘を作成。
- **メリット:**
  - 観点別と統合的視点を完全に分離でき、責務が極めて明確
  - cross-review consistency の自動的な集約が可能
- **デメリット:**
  - **新 Specialist の追加**は intent-spec.md「非スコープ」（L113「新たな Specialist の追加（reviewer / validator / retrospective-writer 等の既存 Specialist は維持）」）に **抵触**
  - lead は他 reviewer の完了を待つ必要があり、純粋な並列起動が崩れる（Step 内の Sequential Workflow が混入）
  - Step を抜ける Gate 判定が複雑化（lead の承認 vs 全 reviewer の Blocker 0 件）
- **判定:** **不採用**。intent-spec.md スコープ違反のため Step 3 (Design) の選択肢から除外。

### I3. 深刻度ラベル統合案 — 推奨と根拠

intent-spec.md L193–L194 が要求する設計判断。

**推奨: Blocker / Major / Minor に統一（External Review 側に寄せる）**

**根拠:**

1. **既存呼称の被影響範囲が小さい**: 削除対象である Self-Review 側のラベル（High/Medium/Low）は廃止されるため、残るのは External Review 側のラベル。既存の `specialist-reviewer` / `references/review-report.md` / `templates/review-report.md` / 「Step 8 External Review」セクション全てが Blocker/Major/Minor を使っており、この決定で**改修は最小**。
2. **「Blocker」が Gate 判定と一致**: External Review の Gate 判定は `approved / needs_fix / blocked` で、`Blocker` ラベルが直接対応する。一方、self-reviewer の `passed/failed (High 残あり)` 二値は Gate との対応が緩い。Blocker/Major/Minor の方が Gate 判定との semantic gap が小さい。
3. **「Major」が「修正すべき。ユーザー承認前に議論が必要」を表現**: 旧 Self-Review の High（修正必須、Step 8 進行不可）は新運用では Blocker（リリース阻害）に再分類されるべき。一方、旧 High でも「Step 8 で判断」のニュアンスがあるものは Major に降格されるケースが想定される。Major のラベルがある方が現実的なグラデーション表現が可能。
4. **マッピング規則案:**

| 旧 Self-Review | 新 External Review | 根拠 |
| --- | --- | --- |
| High | **Blocker** | 「これを残したまま Step 8 に進めない」= 「リリース阻害」と同等の止め方 |
| Medium | **Major** | 「修正推奨。Retrospective で扱うか Step 8 で判断」= 「ユーザー承認前に議論が必要」と同等 |
| Low | **Minor** | 「記録のみ、提案レベル」= 「記録のみ、改善提案レベル」と同義 |

5. **High → Major のマッピングは慎重**: Self-Review の High には「Task Plan 未実装」「Intent Spec 成功基準未達の恐れ」のような **Validation でも止まる強い指摘** も含まれる。これらは Blocker として扱う必要がある。本マッピングは**一律変換ではなく指摘内容で再判定**する方針が妥当。Task Plan 未実装 / 成功基準未達は Blocker、テスト網羅不足やエラーハンドリング甘さは Major、命名甘さは Minor、と振り分け基準を `references/review-report.md` に追記する案を推奨。

### I4. ループ運用 — 旧 Self-Review 3 周ナレッジの移植先

intent-spec.md L195「External Review ループ運用の詳細」が要求する設計判断。

**推奨運用:**

```
Round 1: 全 reviewer (security / performance / readability / test-quality / api-design / holistic) を並列起動
   ↓
   Blocker 検出?
   ├─ Yes → Step 6 再活性化
   │         ・該当タスクを TODO.md で in_progress に戻し re_activations++
   │         ・新規 implementer 起動（前 reviewer は Step 7 継続維持）
   │         ・修正 diff コミット → 既存 reviewer 群が再レビュー
   │         ↓
   │      Round N に進む
   └─ No  → Major / Minor を Artifact-as-Gate-Review でユーザー承認
            ↓
         Step 8 (Validation) へ

ループ上限: 同一 reviewer 群の Blocker 指摘で **3 周以上**ループする場合、
  設計レベルの問題を疑い Step 3 へロールバック検討
  （旧 Self-Review の 3 周ループ知見を移植）
```

**ループ上限知見の保存先（推奨）:**

- **第一義:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` の「Step 6 ↔ Step 7 ループ」セクション（旧 L437–L464 の自然な後継）
- **第二義:** `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の「失敗モード」表に「Blocker 指摘が 3 周以上発生 → 設計レベル疑い、Main に Step 3 ロールバック相談」を追記
- **第三義（任意）:** `references/review-report.md` の「修正ラウンド履歴」セクションを新設し、Round 単位の Blocker 件数推移を記録できる template フィールドを追加

intent-spec.md L197「旧 Step 7 ループ知見の保存先」の選択肢として、「retrospective.md か specialist-reviewer 本文か」が問われているが、**両方に書き分ける**のが妥当（dev-workflow/SKILL.md = フローの普遍ルール、specialist-reviewer = Specialist の失敗モード対応）。retrospective テンプレート側の `Step 6 ↔ Step 7` 表は External Review 表現で残す（intent-spec.md L83–L85 で更新対象）。

### I5. 並列起動時のスコープ重複 — Main 側のマージ運用

intent-spec.md L196 が要求する設計判断。

`references/review-report.md` L104–L116 に既存の「矛盾記録フォーマット」（矛盾対象 / 相手の主張 / 自分の立場 / 根拠の違い / 推奨）が存在するため、**統合後もこのフォーマットを共通利用**するのが最小コスト。`holistic` 観点が追加されると重複は増える可能性が高いが、以下の運用で吸収可能:

- holistic reviewer は「他観点が指摘していない全体俯瞰問題」「観点を横断する整合性問題」「Intent Spec 成功基準充足見込み」「Task Plan 完了判定」のみを記録するよう本文で明示限定する
- 他観点の reviewer が holistic reviewer と同じ問題を見つけた場合、**より具体的な観点側に主指摘を残し、holistic 側はクロスリファレンスで参照**する運用ルールを `specialist-reviewer/SKILL.md` に追記
- Main は Step 7 完了時に全 review report を読み比べ、重複指摘の集約・優先付けを `progress.yaml.review` 配下に記録する

### I6. agent description / Do NOT use for の更新案

intent-spec.md L198 / L165 で要請。`plugins/dev-workflow/agents/reviewer.md` の description は現状約 250 文字。以下のような書き換え案:

```yaml
description: >
  dev-workflow Step 7 (External Review) 担当の専門エージェント。1 つのレビュー観点
  （セキュリティ / パフォーマンス / 可読性 / テスト品質 / API 設計 / 全体整合性 のいずれか
  1 つ）に特化して、実装者と独立した視点で品質を検証し、Review Report を作成する。
  全体整合性観点は Task Plan 完了判定・Intent Spec 成功基準充足見込み・観点横断の
  bug 検出を担う。観点ごとに並列起動される前提（1 インスタンス = 1 観点）。Main が
  サブエージェントとして起動する。
  Do NOT use for: 成功基準の実測判定（validator を使う）、設計そのものの妥当性検証
  （architect フェーズで実施済みの前提）、複数観点を単一 reviewer で統合（観点ごとに
  別インスタンス）。
```

文字数: 約 280 文字。intent-spec.md L165 の「250 文字程度」に対しやや長いが、「holistic 観点の責務追記」「self-reviewer 言及削除」のトレードオフとしては許容範囲。さらに圧縮するなら「Task Plan 完了判定・Intent Spec 成功基準充足見込み・観点横断の bug 検出を担う」を「全体俯瞰での整合性検証を担う」に短縮可能（約 250 文字以内に収まる）。

`specialist-reviewer/SKILL.md` の description も同様のパターンで改訂。intent-spec.md L143「成功基準 #11」（「全体整合性」または「整合性」キーワードが grep で検出されること）を満たすため、description と本文の両方に「全体整合性」を含める必要がある。

### I7. その他の設計確定事項（design.md で扱う）

- **`progress.yaml` の `review` フィールド構造** (intent-spec.md L196): 現状リスト構造を維持し、`<aspect>` に `holistic` が増える形が最もシンプル（案 B 採用時）。`self_review` キーは削除。
- **TODO.md の `re_activations` カウンタ意味** (intent-spec.md L196): 「External Review High/Blocker 指摘で Step 6 に戻った回数」に更新。template / reference 双方で文言統一。
- **`status` 欄の継承** (旧 Self-Review template L32 の `open / fixed / wontfix_with_reason`): 旧 Self-Review のみ持っていた指摘単位 status 欄を新 External Review template に移植するか否かは Step 3 で決定。Round 間追跡には有用なため移植推奨。

## 残存する不明点

以下は本 Research の対象外、または Step 3 (Design) で判断する事項:

- **Q1. `holistic` の正式名称**: `holistic` / `consistency` / `integration` / `cross-cutting` のいずれを採用するか。Step 3 で決定。`<aspect>` enum の他値との並びと自然言語的な意味の明確さで選ぶ。
- **Q2. `holistic` reviewer の入力範囲**: 他 reviewer の出力を読むのか（案 C 寄り）、独立に diff のみから判断するのか（純粋な並列）。Main 経由での情報共有ルールを Step 3 で確定。本 Note の推奨は **独立並列**（intent-spec.md スコープ準拠）だが、retrospective 入力としての他 review report 参照は許容しても良い。
- **Q3. Blocker 件数の集約閾値**: ループ上限「3 周以上」は旧 Self-Review の単一 reviewer ベース。N 並列の場合、「全 reviewer の Blocker 合計 0 件」を Round 終了条件にすべきか、あるいは「観点別 Blocker 0 件 + holistic Blocker 0 件」の AND 条件にすべきか。Step 3 で確定。
- **Q4. Round 間で reviewer インスタンスを維持するか**: 旧 Self-Review は同一インスタンス維持。新 External Review は Step 完了まで全 reviewer を維持する規律（dev-workflow/SKILL.md L488–L489）。維持コストの見積りは Step 3 で。
- **Q5. Markdown プラグイン特有の「明白な bug」の定義**: 本サイクルは Markdown のみで実行可能コード非該当のため、「明白な bug」は「リンク切れ」「テンプレートとリファレンスの不整合」「frontmatter スキーマ違反」等になる。観点別 reviewer の `holistic` 観点の本文ガイドラインを Step 3 で具体化する。
- **Q6. agent description の文字数厳密化**: intent-spec.md L165「250 文字程度」が strict か soft か。Implementation 段階で実測し、超過なら本文への移譲を検討（Step 6 で対応）。

## 関連リンク

- intent-spec.md: `/Users/totto2727/proj/monorepo/.claude/worktrees/inherited-humming-summit/docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md`
- 直前サイクル retrospective: `/Users/totto2727/proj/monorepo/.claude/worktrees/inherited-humming-summit/docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
- 既存 ADR (フラット step リスト構造): `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md`
- 直前 step 追加サイクル (番号シフトと grep 検証パターンの先例): `docs/dev-workflow/2026-04-26-add-qa-design-step/`
