# Intent Spec: Retrospective Cleanup — 2 過去サイクルの残提案項目の段階的反映

- **Identifier:** 2026-04-29-retro-cleanup
- **Author:** intent-analyst Specialist (auto モード、Main からの初期要求を要約・確定)
- **Created at:** 2026-04-29T10:00:00Z
- **Last updated:** 2026-04-29T10:00:00Z

## 背景

`dev-workflow` プラグインは過去 3 サイクルのメタ改修を経て現在の 9-step / 9 specialist 構成に到達した。各サイクルの retrospective には次サイクル送りとなった「残提案項目」が累積しており、本サイクルはそれを 1 サイクルにまとめて消化する **メタ改修第 4 弾** に位置付けられる。

参照対象 retrospective:

- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
  - 「課題 / Deferred Major」: `main-workflow/SKILL.md` 479 行 (M#1)、main-{inception,construction,verification} の boilerplate 重複 (M#2)、`shared-artifacts/SKILL.md` ↔ `main-workflow/SKILL.md` の保存構造 ASCII 図重複 (M#3)
  - 「次回改善案 / スキル改善」: `specialist-common/SKILL.md` の L144–162 / L175–183 / L186–193 を `references/` 切り出し、specialist-* description の 200–300 文字圧縮
  - 「次回改善案 / Specialist プロンプト改善」8 件 (intent-analyst / researcher / architect / planner / implementer / self-reviewer / reviewer / validator / retrospective-writer)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
  - 「次回改善案 / プロセス改善」: planner reference に `shared-artifacts/references/*` 全件スキャンルール、`progress.yaml` 編集時の運用統一、gsed placeholder 規約 (implementer reference)、大規模修正タスクのサブタスク分解推奨
  - 「次回改善案 / スキル改善」 + 「Specialist プロンプト改善」: researcher の言語スキル棚卸し / architect の代替案 3-5 案推奨 / reviewer の backward-compatibility / validator のバッチスクリプト化 / implementer の placeholder ベスプラ等
- `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
  - 「次回改善案 / プロセス改善」: gsed `-e` 連鎖の禁止 + 2-phase placeholder ルール、メタサイクル baseline commit の明示特定、design.md 章節 ↔ template/reference の機械的紐付け
  - 「次回改善案 / Specialist プロンプト改善」: holistic 観点の Round 1 必須チェック、validator の deprecation 文書化 vs grep 検出のトレードオフ など

直前サイクル `2026-04-29-integrate-self-review-into-external` で既に対応済みの項目（**本サイクル非対象**）:

- Self-Review 削除 + External Review への holistic 観点統合
- 深刻度ラベル統一 (旧 Self-Review High/Medium/Low → External Review Blocker/Major/Minor)
- 3 周ロールバック規則の reviewer 移植
- `backward-compatibility` 観点の holistic 吸収
- 機械検証バッチスクリプト化（design.md / validation-report.md の grep コマンド集合）
- `self_reviewer_improvement` フィールド削除
- `qa-analyst` Specialist プロンプト改善欄の追加

また、以下は既に物理的に存在しないため**非スコープ**:

- 旧 `main-{inception,construction,verification}` 3 スキル（既にフラット化で削除済み、boilerplate 重複問題は霧散）
- `ai-dlc` キーワード衝突（既に `dev-workflow` 改名で解消）
- `main-workflow/SKILL.md`（既に `dev-workflow/SKILL.md` にリネーム済み。820 行 / 3,733 語であり skill-reviewer G3 (5,000 語以下) に違反していないため本サイクルでは圧縮対象としない）

本サイクルは `dev-workflow` プラグインの**自己改修**（meta-reflexive 開発）であり、変更対象は Markdown のみ。実行可能コードを含まない。

## 目的

3 つの retrospective に蓄積した残提案のうち、**`plugins/totto2727/skills/skill-reviewer/SKILL.md` のルール (G1-G7) に違反している項目および新規追加価値のある運用ルール** を選別して反映する。

skill-reviewer ルールへの照合結果、現状の dev-workflow プラグインは以下の通り **構造的違反なし**:

- **G2 #5 (description ≤ 1024 文字)**: 全 9 specialist + specialist-common が 410-775 文字で違反なし
- **G3 / G7 (SKILL.md 5,000 語以下)**: 最長の `dev-workflow/SKILL.md` でも 820 行 / 3,733 語で違反なし。他全ファイルも違反なし

そのため本サイクルは **構造的圧縮 (行数 / description) を含めず**、過去 retrospective で明文化された運用ルール追記のみに絞る:

1. **本文への運用ルール追記**: gsed 2-phase placeholder / `git revert` を regression 修正の第一選択にする / design.md ↔ template/reference 紐付け / 影響範囲スキャン / 代替案 3-5 案推奨 / progress.yaml 編集ルールなど、過去 retrospective で明文化されたベストプラクティスを各 Specialist の本文・各 reference に追記する
2. **specialist-reviewer の holistic 観点小節新設**: research で発見した未反映項目 (本文「観点別のレビュー指針」セクションに holistic 小節が完全欠落) を補完

直前サイクル retrospective が挙げた「baseline commit を design.md に明示記録する」は本サイクル**非対象**。これはパーミッション制約で `git revert` がブロックされたときの手動復元を前提とした workaround であり、本来は `git revert` を第一選択にすれば不要になる。本サイクルは A-1 で「git revert を最初に試す」ルールを implementer に追記することで、根本原因側を是正する。

成功条件は「retrospective 由来の運用ルールが grep で検出できる、specialist-reviewer 本文に holistic 小節が存在する、既存の skill-reviewer ルール違反を新たに発生させない」状態に到達すること。

## スコープ

### A. 本文への運用ルール追記 (Specialist 改善)

各項目に **「なぜ必要か (再現された事故 / 失敗モード)」と「出典 retrospective ファイルパス + 行番号」** を併記する。読者が項目を見て scope に納得できない場合は、出典の retrospective を直接確認できる構造とする。

#### A-1. specialist-implementer

`plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の失敗モード表または手順節に以下 2 点を追加:

1. **gsed `-e` 連鎖は禁止、必ず 2-phase placeholder で機械置換する**
   - 例: `old → __SRK_NEW<n>__` を別 sed 呼び出し、`__SRK_NEW<n>__ → new` で復元、実行前後に `ggrep -F __SRK_ <root>` で 0 件確認
   - **なぜ必要か**: 直前サイクル T2 で `gsed -i -e 's/Step 10/Step 9/g' -e 's/Step 9/Step 8/g' -e 's/Step 8/Step 7/g'` を実行した結果、同一行内で `Step 10 → 9 → 8 → 7` と連鎖し、Step 8/9/10 全てが Step 7 に圧縮される事故 (commit `9125656`) が発生
   - **出典**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L34-L39 (T2 chain bug 記録) / L78 (改善案)
   - **間接出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L22 (placeholder 経由の保護) / L30 (chain bug 警告) / L56 (implementer reference に追記推奨)

2. **regression を発見したら最初に `git revert <bug commit>` を試す**。手動の `git show <commit>:<file> > <file>` 復元は最後の手段。revert がパーミッション等で失敗した場合は Main 経由でユーザーに状況を報告し判断を仰ぐ
   - **なぜ必要か**: 直前サイクル T2 chain bug 修正時、`git revert --no-commit 770907b 9125656` がパーミッション制約でブロックされた直後に手動 `git show ... > <file>` 復元へ走ってしまい、結果として baseline commit 選定ミス (`1bac43f → 6a1c5b9` の 2 段やり直し) を誘発。`git revert` を最初に試して通ればこの事故全体が回避できた
   - **出典**: 本サイクルの Step 1 ユーザー対話で確定した新規ルール (直前 retrospective には未記載、本 Intent Spec で明文化)

#### A-2. specialist-architect

`plugins/dev-workflow/skills/specialist-architect/SKILL.md` 本体の代替案分析手順を更新:

- 「**代替案分析は 3-5 案を推奨**」（現行 2-3 案 → 3-5 案）に更新
  - **なぜ必要か**: `2026-04-26-add-qa-design-step` サイクルで「5 トピック × 各 2-4 案」の代替案分析を実施したところ、後段でのユーザー指摘 (qa-flow.md は実装都合テストも図示) のような方針変更が発生しても影響範囲が局所的だった (=代替案数が増えるほど方針変更耐性が高まる)。一方 2-3 案では選択肢を絞りすぎて事後修正が必要になる傾向があった
  - **出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L21 (良かった点 / 代替案 5 トピック) / L72 (改善案 / 「2-3 案」から「3-5 案」へ)

#### A-3. specialist-planner

`plugins/dev-workflow/skills/specialist-planner/SKILL.md` 本体に以下 3 点を追加:

1. **task-plan 作成時に `shared-artifacts/references/*` 全件をスキャンして影響範囲を確認する**
   - **なぜ必要か**: `2026-04-26-add-qa-design-step` サイクルで T6 範囲外だった `references/*` が Step 5 中に発覚 (design.md / retrospective.md / todo.md など)、追加 gsed バッチで対応する手戻りが発生
   - **出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L31 (課題 / refs 漏れ) / L54 (改善案)

2. **大規模修正タスクは複数サブタスクに分解** することを推奨
   - 例: `dev-workflow/SKILL.md` 全面書き換えの場合、ステップテーブル / 全体図 / 詳細セクション / コミット規約 / 並列ガイド / ロールバック表 を別 subtask に分割
   - **なぜ必要か**: `2026-04-26-add-qa-design-step` の T3 (`dev-workflow/SKILL.md` 大規模修正、246 行 diff) が単一 commit で生成され、ユーザー側の GitHub レビュー時に変更を局所化できなかった。`2026-04-29-integrate-self-review-into-external` サイクルで T3a-T3d の 4 サブタスクに分割した結果、各 commit が小さく目視レビューしやすくなり実証された
   - **出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L32 (課題) / L57 (改善案)

3. **design.md の章節 ↔ template/reference を紐付ける記法**（例: 各タスクの「設計参照」欄に design.md の対応セクション L 範囲を明記し、影響範囲が `templates/` / `references/` に及ぶ場合はファイル名を列挙）
   - **なぜ必要か**: 直前サイクル Step 7 Round 1 で発生した Major 指摘の根本原因の多くが「design.md L324 で約束した修正ラウンド履歴セクションを T4 が見落とした」というもの。planner が紐付けを機械的にチェックしていれば事前検出可能だった
   - **出典**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L52 (根本原因 / 機械的紐付けの欠如) / L80 (改善案) / L89 (planner への反映提案)

#### A-4. specialist-researcher

`plugins/dev-workflow/skills/specialist-researcher/SKILL.md` 本体にデフォルト調査項目を追加:

- **該当言語のプロジェクト固有スキル棚卸し**観点
  - **なぜ必要か**: `2026-04-26-add-qa-design-step` の T2 (project-skills) で「該当言語スキル」の棚卸しが効果的だった。dev-workflow は言語固有スキル (effect-layer / totto2727-fp / vite-plus 等) と組み合わせて使うため、サイクル開始時点で利用可能なスキル群を確認しないと Specialist 起動時の input 不足が発生する
  - **出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L71 (researcher 改善案 / T2 が高品質だった点)

#### A-5. specialist-reviewer

`plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の本文「観点別のレビュー指針」セクションに `holistic` 小節を新設:

- **holistic 小節の内容**: 「design.md と実装の整合性チェックを Round 1 必須項目化」「Task Plan 完了判定」「Intent Spec 成功基準充足見込み」「明白な bug 早期検出」をチェックリスト化
  - **なぜ必要か**: research note `operational-rules-mapping.md` (本サイクル Step 2) で本文 L88-L122「観点別のレビュー指針」に security / performance / readability / test-quality / api-design の 5 観点のみ存在し、`holistic` 小節が完全欠落していることを発見。直前サイクルでは frontmatter description / Step 7 セクションの本文には holistic が反映されたが、本文の観点別小節への反映が漏れていた
  - **出典 (実装課題の根本原因)**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L52 (T4 が design.md 約束を見落とした) / L90 (reviewer 改善案)
  - **出典 (現状の欠落の証拠)**: 本サイクル `research/operational-rules-mapping.md` R14

#### A-6. specialist-validator

`plugins/dev-workflow/skills/specialist-validator/SKILL.md` または `shared-artifacts/references/validation-report.md` に **deprecated フィールドの言い換えで grep 検証を通すパターン** を追記:

- 内容例: 「`self_review` のような廃止フィールド名を deprecation 文書に書く必要がある場合、grep で 0 件を要求する成功基準を満たすため、フィールド名を直接書かず "整合性レポート用キー" のような言い換えで言及する」
  - **なぜ必要か**: 直前サイクル Step 7 Round 2 修正時、Intent Spec の TC-005 (grep 0 件) と api-design Major #2 (deprecated フィールド文書化) が衝突した。フィールド名 `self_review` を文書化するとフィールド名自体が grep ヒットになり成功基準違反になる。言い換えで両立する解決パターンが他の deprecation 案件でも再利用可能
  - **出典**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L78 後半 (再利用可能な知見) + Step 7 Round 2 修正コミット `6afa785` (実証ケース)

#### A-7. specialist-intent-analyst

`plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md` 本体に **メタサイクルでの「言い換えグレーゾーン」許容明記手順** を追加:

- 内容: 「Intent Spec の成功基準に grep ベース検証を含む場合、deprecation 文書化等で grep 検出を回避する言い換えを許容する旨を Intent Spec の成功基準セクションに明記する。検証時の判定が言い換えと禁止表現で混乱しないよう、Specialist が事前合意できる文書化を要求する」
  - **なぜ必要か**: A-6 と同じ事象。validator 側の運用だけで対応すると Intent Spec との不整合が発生するため、intent-analyst 段階で「許容する言い換えがある」を明示しておく必要がある
  - **出典**: A-6 と同じ。Intent Spec 側のガード追加であり validator 側のルールとセットで成立

#### A-8. specialist-retrospective-writer

`plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` 本体に **再活性化が 1 回以上発生したタスクの SHA 列挙手順** を追加:

- 内容: 「retrospective.md 作成時、`TODO.md` の `re_activations >= 1` のタスクについて再活性化を引き起こした修正コミット SHA を列挙する」
  - **なぜ必要か**: 直前サイクル T2 chain bug → T3a 復元やり直し で `re_activations: 1` が記録されたが、retrospective.md にはこのカウンタの根拠 (どの commit で再活性化が発生したか) が散発的にしか記載されなかった。次サイクルで「同種事故が起きた commit を grep で発見する」フックがないため、Specialist 段階で SHA 列挙を標準化する
  - **出典**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L27 (TODO.md re_activations 動作実証) / L70 (Blocker 化閾値の議論) / L91 (改善案)

### B. shared-artifacts/references/* への運用ルール追記

各項目に出典を併記:

- `shared-artifacts/references/progress-yaml.md` に **新フィールド追加時は既存 null フィールドを置き換える (削除 → 追加ではなく上書き)** 運用ルールを明記
  - **なぜ必要か**: `2026-04-26-add-qa-design-step` で task_plan / self_review の **キー重複エラー** が pre-commit hook で 2 回検出された (新フィールド追加時に既存 null フィールドを残してしまう)
  - **出典**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L29 (課題) / L55 (改善案) / L66 (progress-yaml reference 改善案)

- `shared-artifacts/references/task-plan.md` に **全 reference スキャンルール** および **大規模修正タスクのサブタスク分解推奨** を追記 (A-3 の真のソースを reference 側に置き、planner 本体からは 1 行参照のみ)
  - **なぜ必要か**: A-3 と同じ。bootstrap retrospective M#3 と同種の「真のソース重複」アンチパターンを避けるため、真のソースは reference 側に置く
  - **出典**: A-3 と同じ

- `shared-artifacts/references/implementation-log.md` に **gsed 2-phase placeholder ベストプラクティス** を簡潔に記述 (specialist-implementer 本体との重複を避け、reference では具体例のみ)
  - **なぜ必要か**: A-1 と同じ。implementer 本体は「ルール」、reference は「具体例 / コマンド例」と役割分担する
  - **出典**: A-1 と同じ

- `shared-artifacts/references/design.md` に **代替案 3-5 案推奨** および **design.md 章節 ↔ template/reference 紐付け表記法** を追記 (A-2 / A-3 の真のソース置き場として)
  - **なぜ必要か**: A-2 / A-3 と同じ。設計時の判断材料を design reference 側に集約することで、architect / planner の両方が同じソースを参照できる
  - **出典**: A-2 / A-3 と同じ

### スコープ運用

- 影響範囲は `plugins/dev-workflow/` 配下のみ
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) は遡及修正禁止（完了済み履歴として保持）
- 各 Specialist 本文への運用ルール追記は既存 SKILL.md の構造を維持し、新規セクションを作る場合でも 30 行以内に収める
- `references/` の新規ディレクトリは作成しない（既存の `shared-artifacts/references/*` への追記のみ）

## 非スコープ

- **過去サイクル成果物 `docs/dev-workflow/2026-04-*/` の遡及修正**
- **既に廃止済み旧 `main-{inception,construction,verification}` 3 スキル**（実体が存在しないため）
- **既に解消済み `ai-dlc` キーワード衝突**（dev-workflow 改名で解消済み）
- **既に解消済み Self-Review 削除関連**（直前サイクルで完了済み）
- **既に解消済み深刻度ラベル統一**（直前サイクルで完了済み）
- **新規 Specialist の追加**（既存 9 体を維持）
- **`dev-workflow` プラグインの実行可能コード化**（Markdown のみ）
- **マーケットプレイス公開の方針決定**
- **観点別 reviewer の並列度上限の変更**
- **ステップ削除・追加に伴うフェーズ概念の再導入**（フラット 9-step リストを維持）
- **新規 ADR の起票**（本変更は dev-workflow プラグイン内のスキル責務再配置であり横断的決定ではないため、必要なら design.md で記録）
- **「次回サイクルで実機能ドッグフード時に検証」項目**（intent-analyst の validator 事前相談・implementer の context window 予算見積りなど、実機能サイクルでなければ検証できない提案は本サイクル非対象）
- **保存構造 ASCII 図の真のソース化作業**（既に dev-workflow 側 L621-L622 で参照リンク化されており、再確認のみで実質作業なし）
- **specialist-common 以外のスキルへの description ガード**（specialist-common は本サイクル外から呼ばれない構造のため description 制約は緩い）
- **`dev-workflow/SKILL.md` および他 SKILL.md の行数 / 語数圧縮**（skill-reviewer G3 / G7 違反なしのため）
- **specialist-* description の圧縮**（skill-reviewer G2 #5 の 1024 文字以内に全件収まっており、Do NOT use for を本文に移すと負のトリガー機能を失うため逆効果）
- **`references/` 新規ディレクトリ作成**（`dev-workflow/references/` / `specialist-common/references/` のいずれも skill-reviewer 違反でないため作成不要）
- **baseline commit の design.md 記録ルール追加**（本来は `git revert` を第一選択にすれば不要。手動復元時の事故予防策ではなく根本原因 = revert を試さなかったこと、を A-1 で是正する）

## 成功基準

ファイル削除・更新の達成度を観測可能な形で計測する。`<root> = plugins/dev-workflow/`、コマンドは monorepo ルートから実行する前提。`gwc -l` / `ggrep` を使用する。

### A. 本文への運用ルール追記の検証 (grep でキーワード検出)

1. `ggrep -nE '2-phase|placeholder|__SRK_' plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の結果が **1 件以上**（gsed 2-phase placeholder ルールが本文に追記されている）
2. `ggrep -nE 'git revert|revert <bug|手動復元' plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の結果が **1 件以上**（regression 修正は git revert を第一選択とするルールが本文に追記されている）
3. `ggrep -nE '3-5|3〜5|3 から 5|3.{0,3}案.{0,3}5' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/design.md` の結果が **1 件以上**（代替案 3-5 案推奨が architect 本文または design reference に記載されている）
4. `ggrep -nF 'shared-artifacts/references/' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に全 reference スキャンルールが記載されている）
5. `ggrep -nE 'サブタスク|サブ.?タスク|sub.?task' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に大規模修正タスクのサブタスク分解推奨が記載されている）
6. `ggrep -nE '章節|セクション.{0,5}紐付|template.*reference|references.*templates' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（design.md 章節 ↔ template/reference 紐付け表記法が記載されている）
7. `ggrep -nE 'プロジェクト固有スキル|言語スキル|プロジェクト.?固有' plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の結果が **1 件以上**（researcher 本文に言語/プロジェクト固有スキル棚卸し観点が記載されている）
8. `ggrep -nE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**（holistic 観点に design.md ↔ 実装整合性チェックが記載されている）
9. `ggrep -nE 'deprecated|言い換え|文書化.*例外' plugins/dev-workflow/skills/specialist-validator/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md` の結果が **1 件以上**（validator または validation-report reference に deprecated 言い換えパターンが記載されている）
10. `ggrep -nE '上書き|null フィールド|既存 null|新フィールド' plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` の結果が **1 件以上**（progress-yaml reference に新フィールド追加時の上書きルールが記載されている）

### B. specialist-reviewer の holistic 小節新設

11. `ggrep -nE '#### holistic|^#### *holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**、または「観点別のレビュー指針」セクション内に `holistic` を独立小節として持つ（research note `operational-rules-mapping.md` で本文に小節が完全欠落と確認済み）

### C. 既存機能の維持 (skill-reviewer ルール非違反の維持)

12. `gwc -w plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **5,000 語以下**（skill-reviewer G3 / G7 違反を新たに発生させない、現状 3,733 語）
13. `gwc -w plugins/dev-workflow/skills/specialist-*/SKILL.md` 各ファイルが **5,000 語以下**
14. `gwc -l plugins/dev-workflow/skills/specialist-*/SKILL.md` で各 specialist 本体行数が **既存比 +30% 以内** に収まる（追記による肥大化を抑制）
15. **全 specialist description が skill-reviewer G2 #5 の上限 1024 文字以内を維持**（追記により description を伸ばさないことを確認）
16. 既存 ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造方針に違反しない
17. 既存の grep ベース成功基準パターン (`grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が 0 件等) を破壊しない（直前サイクルの達成状態を維持）

## 制約

### 技術的制約

- 全ファイルは Markdown / JSON / YAML のみ（実行コード非該当）
- macOS 環境のため `gsed` / `ggrep` / `gwc` を使用（`macos-cli-rules` スキル準拠）
- 大規模機械置換が発生する場合は **gsed `-e` 連鎖を禁止** し、2-phase placeholder で実施する（直前サイクル T2 chain bug の教訓を本サイクルでも適用）
- 各 Specialist 本文への追記は既存セクション末尾に追加するか、独立した小節 (≤ 30 行) として配置する。既存内容を破壊しない
- 本サイクルは新規ディレクトリ作成・行数圧縮・description 圧縮を行わない（skill-reviewer ルールに違反していないため）

### 規範的制約

- `dev-workflow` の基本方針（Main-Centric Orchestration / One-Shot Specialist / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence）は全継承
- 既存 ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造（フェーズ概念非導入）を維持
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) の遡及修正禁止
- monorepo 共通の memory rules: `gsed` 使用 / `2>&1` 不使用 / `vp run` 経由 / `as` 型アサーション禁止 (TS の場合) / git commit は sandbox 外実行 / `npx` 禁止
- ドキュメント言語: 既存スキル本文の日本語踏襲、frontmatter / template / agent description は英語または既存踏襲

### 組織的制約

- 作業者は totto2727（Main 兼 設計者）。本サイクルは単独実行
- レビュー単位は各ステップ完了時の Artifact-as-Gate-Review（auto モード進行）
- 期限なし（ユーザーの判断ペースに合わせる）
- baseline commit: `4f9e7dd docs(dev-workflow/2026-04-29-retro-cleanup): initialize cycle`（直前サイクル完了 commit `fd0f930` の直後）

## 関連リンク

- 直前サイクル retrospective: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
- bootstrap retrospective: `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
- add-qa-design-step retrospective: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
- 既存 ADR: `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md`
- 直前サイクル Intent Spec（番号シフト先例）: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md`
- 既存スキル: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`, `plugins/dev-workflow/skills/specialist-common/SKILL.md`, `plugins/dev-workflow/skills/specialist-*/SKILL.md` 全 9 体
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` および `templates/`, `references/` 全般

## 未解決事項

(主要意思決定はユーザー要求 + intent-analyst による auto モード判断で確定済み。以下は Step 2 Research / Step 3 Design / Step 4 QA Design で確認・決定する細部)

- **本文追記の重複回避方針**: gsed 2-phase placeholder ルールを specialist-implementer 本体と shared-artifacts/references/implementation-log.md の両方に書くと、bootstrap retrospective M#3 と同じ「真のソース重複」アンチパターンを再現するリスクあり。Step 3 で「真のソースは specialist-implementer 本体、reference は 1 行参照のみ」のような原則を確定
- **specialist-retrospective-writer 本体への追記 vs template 直接追加**: 「再活性化が 1 回以上発生したタスクの SHA 列挙」欄を retrospective.md template に追加するかどうかは Step 3 で決定
- **specialist-reviewer 本文の holistic 追記の現状確認**: 直前サイクルで holistic 観点の責務追加は実施済みのため、research note `operational-rules-mapping.md` で「観点別のレビュー指針」セクションに holistic 小節が完全欠落していることを確認済み。Step 3 で本文への小節新設方針を確定
- **task-plan の Wave 構造**: 本サイクルは A (specialist 本文追記) と B (shared-artifacts/references 追記) の 2 軸に絞られたため、Step 5 で並列 Wave 化を検討
- **gsed 機械置換の有無**: 本サイクルは新規追記が中心で、機械置換は基本不要。仮に発生する場合は 2-phase placeholder を必須とする
