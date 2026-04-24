# Review Report: performance

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Aspect:** performance
- **Reviewer:** verification-step7-external-review-performance
- **Reviewed at:** 2026-04-24
- **Scope:** AI-DLC プラグイン (`plugins/ai-dlc/`) のスキル群を読み込み時のパフォーマンス観点（SKILL.md サイズ / 進行的開示 / 重複コンテンツ / description によるスキル同時活性化コスト / context window 消費）で評価する。プラグイン実行速度（I/O スループット等）は対象外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 3    |
| Minor   | 5    |

**Gate 判定:** needs_fix

パフォーマンス観点では **Blocker 0 件**。ただし Main フェーズで複数スキルが同時に高い確率で読み込まれる設計（main-workflow + main-<phase> + shared-artifacts + specialist-common + 役割別 specialist-*）のため、**context window 使用量の削減余地が明確に存在する**。`main-workflow` は 479 行と skill-reviewer の推奨上限 500 行の 96% に到達しており、早期の進行的開示（references/ への切り出し）を推奨する。

---

## 指摘事項

### #1 `main-workflow/SKILL.md` が推奨上限 (500 行) に肉薄している

- **深刻度:** Major
- **該当箇所:**
  - Commit: HEAD (worktree)
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md`
  - Line: 1–479 (全体。特に L329–411 "ステップ完了時のコミット規約"、L277–326 "プロジェクト固有ルールとの関係"、L414–425 "フェーズ遷移時の引き継ぎ")
- **問題の要約:** 479 行 / 1,704 words で、skill-reviewer が推奨する上限 500 行にあと 21 行しか余裕がない。さらに main-* 系スキルは Main が Inception/Construction/Verification に入るたびに `main-workflow` と合わせて読み込まれる構造のため、このスキル単体の肥大化は context window 全体に 1:1 で効いてくる。
- **根拠:** skill-reviewer の一般則として「SKILL.md は 500 行 / 5000 words 以内」。特に以下のセクションは運用詳細であり `main-workflow/references/` に切り出す余地がある:
  - L329–411 コミット規約の表 3 つと具体的コミット例（Main が毎ターン読む必要はない。ステップ完了時のみ参照）
  - L277–326 プロジェクト固有ルールとの関係（衝突判定の判例が 5 行あり、具体的事例は references 側で十分）
  - L414–425 「フェーズ遷移時の引き継ぎ」表（既に shared-artifacts に重複情報がある）
- **推奨アクション:** 上記 3 セクションを `plugins/ai-dlc/skills/main-workflow/references/commit-policy.md` / `project-rule-integration.md` / `phase-transition.md` に切り出し、SKILL.md 本体はそれぞれ 2–5 行のサマリ＋リンクに置き換える。目標: 本体 300 行以下、2 フェーズ分の再読み込みで累計 1000 行以内。
- **設計との関連:** design.md の「スキル分割方針（Main Skill Split）」および「Progressive Disclosure」原則。

### #2 Main 系 4 スキル冒頭の boilerplate が重複し、同時起動時に同じ文章が 4 回読まれる

- **深刻度:** Major
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/main-inception/SKILL.md` L26 / `main-construction/SKILL.md` L26 / `main-verification/SKILL.md` L28
  - Line: 各々の「**このスキルは `main-workflow` スキル配下で使用される。** `main-workflow` の基本方針・役割定義・調整プロトコル・ユーザー承認ゲート規則（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions の区別）をすべて継承する。」
- **問題の要約:** 3 つの main-* フェーズスキルに**完全同文**のリンク文が存在する（gfind 相当の grep で確認）。さらに `shared-artifacts/SKILL.md:152` にも類似の参照文がある。Main がフェーズ遷移で main-workflow + main-<phase> を一緒に読む典型運用では、同じ情報が 2 回入る。
- **根拠:** プラグイン全体を通して「main-workflow に委譲する」旨を宣言している箇所が複数あり（L25 前後、L239 前後の "このスキルが扱わないこと" を含め 5+ 箇所）、重複文字数が無視できない。
- **推奨アクション:** main-<phase> 側のヘッダは「継承元: `main-workflow`。フェーズ固有事項のみ以下に記載。」に短縮（1 行）。詳細な「どのルールを継承するか」の羅列は main-workflow 側にだけ保持し、main-<phase> 側は差分記述に徹する。
- **設計との関連:** design.md の DRY 原則 / Main Skill Split。

### #3 `shared-artifacts/SKILL.md` の保存構造セクションが `main-workflow` と重複している

- **深刻度:** Major
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md`
  - Line: L96–123 (ディレクトリ構造 ASCII 図) と `plugins/ai-dlc/skills/main-workflow/SKILL.md` の同一内容が `progress.yaml` 関連で重複している。両スキルが同時に読み込まれるケース（Specialist 起動時に Main が両方を入力として渡す運用）で同じ情報を 2 度負担。
- **問題の要約:** 「`docs/ai-dlc/<identifier>/` 配下の成果物レイアウト」と「`<identifier>` 命名ルール」が、main-workflow と shared-artifacts の両方に存在する。main-workflow 側 L262–273 で shared-artifacts を参照しつつ、shared-artifacts 側でも完全な ASCII 構造を再掲している。
- **根拠:** main-workflow L268（`shared-artifacts` SKILL.md の「成果物保存構造」参照）と shared-artifacts L100–123 の重複。前者が「参照する」と言っているなら、後者に**実体だけ**残し main-workflow からは文字通り参照のみにすべき。
- **推奨アクション:** 保存構造 ASCII 図は shared-artifacts に一本化し、main-workflow からは「詳細は `shared-artifacts` SKILL.md の『成果物保存構造』参照」の 1 行のみにする。現状この参照はあるが、隣接セクションで重複情報も提示しており context 効率が落ちている。
- **設計との関連:** shared-artifacts 設計目標「成果物仕様の Single Source of Truth」。

### #4 `specialist-common` の内容が 193 行あり、全 Specialist 起動時に 193 行を読む前提になっている

- **深刻度:** Minor
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/specialist-common/SKILL.md`
  - Line: 1–193
- **問題の要約:** 9 つの Specialist（intent-analyst, researcher, architect, planner, implementer, self-reviewer, reviewer, validator, retrospective-writer）は全て `specialist-common` を継承する。実際の Specialist エージェント起動時は `agents/<role>.md` → `specialist-<role>` SKILL.md → `specialist-common` SKILL.md を順に読むため、どの Specialist も毎回 193 行（492 words）を重ねて負担。
- **根拠:** `specialist-common/SKILL.md` には「8. 命令形・具体性の原則」(L186–193) や「7. Git コミットに関する注意」(L175–183) のように、**役割により必要性が異なる**ルールが同居している。例えば implementer 以外は Git を触らないので「7」を読む必要はない。
- **推奨アクション:**
  - L144–162 の「スコープ規律」は `specialist-common/references/scope-discipline.md` へ
  - L175–183 の「Git コミット」は `specialist-common/references/git-notes.md` へ（implementer からのみ参照）
  - L186–193 の「命令形・具体性」は出力品質ルールなので、各 specialist-* 側の品質基準セクションに統合するか references 化
  - 本体は L1–143（ライフサイクル・入出力・失敗時プロトコル）に絞る
- **設計との関連:** Progressive Disclosure。

### #5 description 欄に長大な Do NOT 節があり、スキル一覧読み込み時のトークンを消費

- **深刻度:** Minor
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/specialist-common/SKILL.md` L12–16、`specialist-intent-analyst/SKILL.md` L10–12、`specialist-retrospective-writer/SKILL.md` L11–14、他 specialist-*
  - Line: 各 frontmatter
- **問題の要約:** `description` フィールドは Claude Code のスキル一覧取得時に毎回ロードされる。`specialist-common` は "Do NOT use for" に 9 つの specialist-* 名を列挙（L12–16）しており、約 480 文字。プラグイン起動時の全スキル description ロードコストが全 15 スキル分で加算される。
- **根拠:** skill-reviewer 的には description は「トリガー判定に必要な最小限」で、否定スコープは本文に置くことが推奨される。9 名列挙するより「Main が Specialist 用に背景として参照。ユーザー直接起動禁止」程度で済む。
- **推奨アクション:** 各 specialist-* および specialist-common の description は 200–300 文字程度に圧縮し、網羅的な除外対象（effect-layer 等含め）は本文の「このスキルが扱わないこと」セクションへ移動。
- **設計との関連:** design.md 「description 品質とトリガー精度」。

### #6 description の広範なキーワード列挙により「ai-dlc」周辺で複数スキル同時活性化の可能性

- **深刻度:** Minor
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md` L8–9、`main-inception/SKILL.md` L8–9、`main-construction/SKILL.md` L7–8、`main-verification/SKILL.md` L8–9
  - Line: 各 description の「起動トリガー」節
- **問題の要約:** 「ai-dlc の inception」「ai-dlc の construction」「ai-dlc の verification」「ai-dlc を開始」「開発ワークフローを実行」等、"ai-dlc" キーワードで 4 つの main-* すべてが候補になる可能性がある。単純なトリガー語マッチなら `main-workflow` で十分のはずが、具体的なフェーズ語（"意図明確化", "外部レビュー" 等）がない簡易な起動指示で複数が同時に候補に上がるリスク。
- **根拠:** main-inception description L8「ai-dlc の inception」、main-construction description L8「ai-dlc の construction」、main-verification L9「ai-dlc の verification」、main-workflow L9「ai-dlc を開始」。いずれも "ai-dlc" を含む。description の Do NOT 節で排他性は確保されているが、一覧上はトップにすべて現れる。
- **推奨アクション:** main-<phase> 側のトリガー例から "ai-dlc の <phase>" は削除し、main-workflow は "ai-dlc 開始 / 全体ワークフロー" 専用、main-<phase> はフェーズ固有語（"Inception", "意図明確化"）のみに限定する。
- **設計との関連:** skill-reviewer の description 設計原則。

### #7 templates と references の内容重複（書式 vs 書き方）

- **深刻度:** Minor
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/review-report.md` L22–49 と `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md` L9–49
  - Line: 「サマリ」「指摘事項」「深刻度の判定基準」のセクション構造
- **問題の要約:** reference の L22–49 は template のセクション構造をなぞって書き方を説明しているが、template 本体自体にもコメント形式でほぼ同じ説明が埋まる（template L7 `<!-- security | performance | ... -->`, L17 `<!-- approved | needs_fix | blocked -->` など）。Specialist はテンプレを参照しつつ reference も読むため、同じ情報を 2 パス読む。
- **根拠:** shared-artifacts 設計上 1:1 対応は理にかなっているが、**内容レベルでの役割分担が不十分**。template はプレースホルダのみ、reference は書き方ガイドと完全分離するのが効率的。現状 template のコメントが reference のミニ版になっている。
- **推奨アクション:** template はコメントを最小化し、reference に全説明を集約。または逆にコメントで十分な場合は reference を短縮。両方に同じサマリ / 深刻度表 / セクション名を記述しない。
- **設計との関連:** shared-artifacts の References/Templates 役割分担。

### #8 Main が Construction に入る時点で同時読み込みが実質 5–6 スキルに達する

- **深刻度:** Minor
- **該当箇所:**
  - Commit: HEAD
  - File: `plugins/ai-dlc/skills/main-construction/SKILL.md` L26 / L39 / L50 / 全体
  - Line: main-workflow / shared-artifacts / specialist-common / specialist-implementer / specialist-self-reviewer への参照
- **問題の要約:** Construction 進行中、Main は少なくとも `main-workflow` (479 行) + `main-construction` (299 行) + `shared-artifacts` (200 行) を常用、加えて implementer 起動時に `specialist-implementer` (97 行) + `specialist-common` (193 行) の入力を渡す。合計 1,268 行 / 約 4,000+ words が 1 ステップ内で流通する。Verification / Inception も同等。
- **根拠:** main-construction L50–53 で「Specialist 起動時には reference / template の両方のパスを入力に含める」とあり、template と reference も計 2 ファイル加わる。
- **推奨アクション:** 上記 #1〜#4 の改善を実施すれば累計 30–40% 削減できる見込み。特に main-workflow と specialist-common の進行的開示が最も効く。
- **設計との関連:** Main-Centric Orchestration の実行コスト試算。

---

## 観点固有の評価項目（performance）

markdown プラグインのパフォーマンスを、アナロジーとして 4 観点（complexity / I/O / memory / concurrency）に対応付けて評価する。

### 計算量評価 (Complexity)

- **Specialist 起動コスト:** O(1) スキル参照（各 Specialist は specialist-common + specialist-<role> の 2 スキルのみ読む）。設計として適切。
- **Main フェーズ遷移コスト:** O(フェーズ数) でフェーズスキルを差し替える構造は良好だが、main-workflow が常駐する前提があり実質 O(1 + phase)。main-workflow の肥大化（#1）で係数が大きい。
- **不要なネスト参照:** main-<phase> → main-workflow → shared-artifacts の 3 段参照が最頻出。参照グラフ自体は浅いが、同情報の再記述（#2, #3）で実効的な重複読みが発生。

### I/O 効率（スキル読み込み / Context Window）

- **ベストケース:** 単一 Specialist 起動時 = specialist-common (193 行) + specialist-<role> (~90 行) + reference + template = 約 400–450 行。**許容範囲**。
- **ワーストケース:** Construction ループ中に Main が全文脈を保持 = 約 1,268 行（#8）。
- **progressive disclosure の実装度:** shared-artifacts が templates/ と references/ を分離しているのは良好。一方 main-workflow と specialist-common は progressive disclosure が未実装（全情報を SKILL.md 1 ファイルに集約）。

### メモリ使用量（Context Window）

- 15 SKILL.md の合計: **2,529 行 / 8,698 words**。Claude Code の推奨（1 スキルあたり 5,000 words）に対し、main-workflow 単体で 1,704 words、合計は推奨枠 1 個分に収まるが、複数スキル同時読みで累計 3,000–4,000 words を常時消費するワークフローとなる。
- 成果物テンプレート 21 ファイル合計 1,679 行は Specialist 起動時に 1–2 ファイルしか使わないため負担軽微。
- **redundant content の定量:** boilerplate 文（#2）で 3 回 × 約 130 字 = 390 字、保存構造 ASCII（#3）で約 700 字、プロジェクト固有ルール列挙（`effect-layer` ほか）が少なくとも 7 箇所で重複。累計 2–3 KB の低効率領域。

### 並行性の正当性（Skill Activation Collision）

- Main 系スキル 4 つが "ai-dlc" キーワードを共有しており、単純な起動指示で複数候補に上がるリスクあり（#6）。Do NOT 節による排他制御はあるが、**description 自体の単語マッチ精度で整理する方が軽い**。
- Specialist 系は「Main がサブエージェント起動」か「明示的な観点指定」に限定しており衝突耐性は良好。
- agents/*.md (35–39 行) と specialist-*/SKILL.md は役割分担が明確で重複小さい。

---

## 他レビューとの整合性

現時点で同サイクル review/ ディレクトリに他レビューファイルは未配置のため、比較対象なし。ただし想定される他観点レビューとの関係を注記:

- **security レビュー:** Performance 観点では `$TMPDIR` 使用（secrets/credentials を一時レポートに書く可能性）は secret 管理として security 観点が主。パフォーマンス観点では `$TMPDIR` へのオーバーヘッドは最小のため、security 指摘と矛盾しない。
- **readability レビュー:** #4 の specialist-common 肥大は「読みやすさ」観点とも共通で、切り出しを両レビューで推奨する可能性。**両者の指摘が補強し合う**見込み。
- **test-quality レビュー:** スキル自体のテスト観点は skill-reviewer 領域で、performance とは独立。

矛盾は現時点で検出なし。

---

## 総合所見

- **Blocker は無いが、context window 使用量削減の余地が明確に存在する**。Major 指摘 3 件（#1〜#3）を優先的に解決すれば、Construction 中の 1 ターンあたり読み込み量を 30–40% 削減できる見込み。
- skill-reviewer の「500 行 / 5000 words」ガイドラインに対し、個別スキルは全て順守しているが、main-workflow が限界値に近い点と、複数同時読み込みの累計量は未評価領域。
- Progressive Disclosure（references/ / scripts/ 切り出し）が shared-artifacts のみ実装済みで、main-workflow / specialist-common は未実装。今後の改修余地として設計に記録を推奨。
