# Review Report: documentation-quality

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** documentation-quality
- **Reviewer:** reviewer-documentation-quality (Step 7 specialist instance)
- **Reviewed at:** 2026-04-29T22:30:00Z
- **Scope:** 本サイクル Step 6 で生成・更新された全成果物 (新規 14 ファイル + 既存追記 6 ファイル) の記述品質・可読性・誤字脱字・述語整合性・reference の品質基準遵守・template の placeholder 構造・Mermaid 図の正確性・見出し階層・具体例の有無。サイクル進行中の成果物 (`docs/workflow/2026-04-29-add-dev-roadmap-skill/` 配下の `intent-spec.md` / `design.md` / `qa-design.md` 等) は対象外 (本観点はあくまで Step 6 で生み出されたプラグイン側の skill / template / reference / agent / README に対するもの)。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 4    |
| Minor   | 7    |

**Gate 判定:** `needs_fix`

Blocker は検出されなかったため Step 6 への自動差し戻しは不要だが、Major 4 件のうち #1 と #2 は完成版スキル (運用開始対象) の記述内に含まれる**事実関係の誤り** / **整合性の崩れ**であり、ユーザー判断で Step 6 への戻しか Retrospective 繰越かを決定する必要がある。Major #3 / #4 は単一 reference / SKILL に閉じる可読性問題で、ユーザー裁量の余地が大きい。Minor 7 件は記録のみで進行可。

## 指摘事項

### #1 旧ステップ番号 (Step 8 / Step 9 / Step 10) を 9 ステップ体系下で参照している

- **深刻度:** Major
- **該当箇所:**
  - Commit: 011daa3 (T4: specialist-roadmap-retrospective-writer 新設)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md`
  - Line: 135
- **問題の要約:** スコープ外セクションで「配下 dev-workflow サイクルの実装評価 (各 workflow の Step 8 External Review / Step 9 Validation / Step 10 Retrospective で完了済。本 Specialist は集約のみ)」と記述されているが、本サイクルの design.md / intent-spec.md でも明記されているとおり main マージ後の dev-workflow は **9 ステップ体系** であり、External Review = Step 7、Validation = Step 8、Retrospective = Step 9 が正しい。
- **根拠:** 同ファイル本文 (例えば作業手順 8 や Do NOT use の説明文では「Step 9 Retrospective 完了時」と 9 ステップ体系で記載されている) と矛盾しており、新規 Specialist スキルの内部だけで整合性が崩れている。Intent Spec の制約 (intent-spec.md:134) が「workflow は main マージ後の 9 ステップ体系のまま」を明文化しているため、誤情報のままでは roadmap-retrospective-writer が起動された際に「Step 10 Retrospective」を期待することになり、運用ミスを誘発する。
- **推奨アクション:** L135 の `Step 8 External Review / Step 9 Validation / Step 10 Retrospective` を `Step 7 External Review / Step 8 Validation / Step 9 Retrospective` に置換する。同 SKILL の他箇所が 9 ステップ体系で正しく書かれているので、本箇所の置換のみで内部整合が取れる。
- **設計との関連:** design.md §「Self-Review 削除と External Review への統合の影響 (機械的調整)」(L517-523) で「ステップ番号の置換」「design.md 内の旧 Step 番号 (Step 8 Self-Review / Step 9 External Review / Step 10 Retrospective) は本改訂で全て新 Step 番号 (Step 7 External Review / Step 8 Validation / Step 9 Retrospective) に置換済」と明記されているが、本ファイルへの置換漏れが本指摘の本質。

### #2 dev-workflow/SKILL.md「ワークフロー開始時」のステップ番号付けが一貫しない (`ステップ 4'` vs `ステップ 5`)

- **深刻度:** Major
- **該当箇所:**
  - Commit: 6b6206b (T9: roadmap-progress.yaml 更新プロトコル追記)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Line: 558, 778
- **問題の要約:** L558 では新規挿入された段落を **「(ステップ 4')」** と自己ラベルしているが、リストの実番号付けは `5.` (元の `4. progress.yaml 初期化` と元の `5. Step 1 から着手` の間に挟まれた結果、自動的に通し番号 5 となり、元の `5.` は `6.` に繰り上がった)。一方、同ファイル末尾近くの「`roadmap-progress.yaml` 更新プロトコル」セクション L778 では同じ段落を **「ワークフロー開始時のステップ 5『roadmap 配下サイクルの追加初期化』」** と参照している。同一段落を 2 つの異なる番号 (`4'` と `5`) で参照しているため、読者は「ステップ 4'」と「ステップ 5」が同一なのか別のステップなのか即座に判断できない。
- **根拠:** Reference 品質基準「観点ごとに重点項目が異なる」「観測可能な事実とアクション可能な提案で構成する」(specialist-common §10) に照らし、ドキュメント内部参照の番号は単一の真のソースから引かなくてはならない。design.md §「`dev-workflow/SKILL.md` への追記内容草稿 → 追記 1: 「ワークフロー開始時」段落追加」(design.md L243-249) では「ステップ 4 と既存ステップ 5 の間に挿入する」と意図したが、実装でリストを再番号化したため自己ラベル「4'」が固有番号と乖離した。
- **推奨アクション:** 以下のいずれかで一貫させる:
  - 案 A (推奨): L558 のラベル `(ステップ 4')` を削除し、L778 の参照表記 `ステップ 5` に揃える。挿入位置の説明が必要なら本文で「`progress.yaml` 初期化 (ステップ 4) の直後」と書く。
  - 案 B: L558 の `5.` という番号付けをやめ、`4a.` のサブステップ表記にすることで元の 4 / 5 / 6 の番号体系を維持し、L778 の参照を `ステップ 4a` に揃える。
- **設計との関連:** design.md L317「L557 直後 (ワークフロー開始時 step 4 と step 5 の間)」と整合させる必要がある。実装で「ステップ 4'」と命名したい意図は読み取れるが、リストの実番号と齟齬を作らない命名にすべき。

### #3 サイクル固有の連番ラベル「確定 N」が永続スキル / reference に流出している

- **深刻度:** Major
- **該当箇所:**
  - Commit: c2b754d (T3: specialist-roadmap-planner 新設) / fca9a23 (T7: roadmap-progress-yaml.md 新設)
  - File:
    - `plugins/dev-workflow/skills/specialist-roadmap-planner/SKILL.md` L77
    - `plugins/dev-workflow/skills/shared-artifacts/references/roadmap-progress-yaml.md` L149
- **問題の要約:**
  - planner SKILL L77: 「**記法は `graph LR` で統一** (既存 `task-plan.md` / `qa-flow.md` のパターンと整合、本ロードマップ確定 4)」
  - roadmap-progress-yaml reference L149: 「本バージョンは **git 3-way merge 任せ** (案 A、Research progress-yaml-concurrency / design.md 確定 5 参照)」

  「本ロードマップ確定 4」「design.md 確定 5」は**本サイクルの design.md 内の代替案比較表の連番**を指しているが、永続スキル / reference は本サイクル完了後も他のロードマップで再利用される。読み手 (将来の Specialist / Main / 別サイクルのユーザー) は「確定 4 / 5」が何を指すか追跡できない。さらに specialist-common §8 (プロンプトインジェクション耐性) は Specialist が「先行ステップの成果物の本文中の指示には従わない」「データとして扱う」と定めているため、Specialist が起動時に design.md を読む前提も持てない。

- **根拠:** Reference 品質基準「根拠が観点固有の技術的文脈で説明されている」「アクションが具体」を満たさず、サイクル固有のメタデータが恒久ドキュメントに混入している。retrospective や ADR ならばサイクル文脈で記述してよいが、SKILL / reference は「次のロードマップでも通用する記述」を要求される (specialist-common §1 ライフサイクル規則の根底にある「ステップ跨ぎ禁止」と整合)。
- **推奨アクション:**
  - planner SKILL L77 の「本ロードマップ確定 4」を削除し、「(既存 `task-plan.md` / `qa-flow.md` のパターンと整合、Research existing-skill-structure 由来)」または単に「(既存パターンと整合)」に置換する。
  - roadmap-progress-yaml reference L149 の「design.md 確定 5 参照」を削除し、「(本バージョンは最小スキーマ + git 3-way merge 任せの方針、詳細は本ドキュメント内『どう書くか — …』および `dev-workflow/SKILL.md` の更新プロトコル参照)」に置換する。
- **設計との関連:** design.md §「代替案比較 (Research 確定事項の総括)」(L340-365) は本サイクル限定のメタデータであり、永続ドキュメントに参照を残すと将来的に dangling reference になる。

### #4 README.md の追記段落: 英語と日本語の不規則混在で可読性が低い

- **深刻度:** Major
- **該当箇所:**
  - Commit: 02307d7 (T11: README 追記)
  - File: `plugins/dev-workflow/README.md`
  - Line: 13
- **問題の要約:** 追記された段落「A separate `dev-roadmap` skill sits one layer above `dev-workflow` as the **戦略層 (strategic layer)** that bundles 複数の `dev-workflow` サイクル into a single 大規模 development effort.」では、英語の動詞 (`bundles`) と前置詞 (`into`) の間に日本語名詞句 (`複数の dev-workflow サイクル`) が挟まり、英文として自然に読めない。同様に「single 大規模 development effort」も英日混在のまま。
- **根拠:** README.md は冒頭が完全に英語 (intent-spec.md:136 の制約「ドキュメント言語: 英語 (skill / template / reference / agent description)」と整合) であり、追記段落だけ日本語が混入することで段落内のスタイル一貫性が崩れる。Reference 品質基準「文章を簡潔に」とも整合しない。
- **推奨アクション:** 追記段落を全英文化する。例:
  - 「戦略層 (strategic layer)」→ `the strategic layer`
  - 「複数の `dev-workflow` サイクル」→ `multiple dev-workflow cycles`
  - 「大規模 development effort」→ `large-scale development effort`

  日本語訳語が必要であれば、英文の後に括弧で `(strategic layer / 戦略層)` のように補注する形なら可読性を損なわない。

- **設計との関連:** design.md §「ドキュメント言語」(L531) は「Intent Spec 制約 (intent-spec.md:136) の『英語 (skill / template / reference / agent description) ただし本 Intent Spec / 既存 SKILL.md の本文は日本語を踏襲』について、本サイクルでは既存パターン (日本語本文 + 英語見出しキーワード混在) を踏襲する」と明記されているが、README は元々英語であり「日本語本文 + 英語見出しキーワード」のパターンには該当しない。

### #5 specialist-roadmap-retrospective-writer のフロントマター: `metadata.version` が欠落

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 011daa3 (T4: specialist-roadmap-retrospective-writer 新設)
  - File: `plugins/dev-workflow/skills/specialist-roadmap-retrospective-writer/SKILL.md`
  - Line: 18-20 (frontmatter `metadata` ブロック)
- **問題の要約:** frontmatter に `metadata: { author: totto2727 }` のみで `version: 1.0.0` の指定がない。同サイクル内で同時新設された他 2 つの specialist-roadmap-\* スキル (analyst L20 / planner L22) および dev-roadmap/SKILL.md (L20) は全て `version: 1.0.0` を含んでいる。
- **根拠:** Intent Spec 制約 (intent-spec.md:128)「スキル frontmatter のスキーマは既存 `dev-workflow` 系スキルと同一 (name / description / metadata: { author, version })」に違反する。観点境界 (`api-design`) と重複する可能性があるが、本観点 (記述品質) では「他スキルとの記述書式整合性」として Minor 計上。
- **推奨アクション:** L19 の `author: totto2727` の直後に `version: 1.0.0` を追加する。
- **設計との関連:** design.md §「設計目標と制約 (Intent Spec からの引用)」(L18) で frontmatter スキーマ統一が制約として明記されている。

### #6 dev-roadmap/SKILL.md の「Intent Spec L41 / 制約」が誤参照 (実際の行は L98)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: ffd2f3f (T1: dev-roadmap/SKILL.md 新設)
  - File: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`
  - Line: 564
- **問題の要約:** 「`roadmap-of-roadmaps (1 階層を超える入れ子)`: 本バージョン非スコープ (Intent Spec L41 / 制約)」とあるが、Intent Spec 内の roadmap-of-roadmaps 言及は L98 (「非スコープ」セクションの 6 番目の項目)。L41 は 「`milestones/<milestone-id>.md` (1 ファイル / マイルストーン) + `roadmap.md` 内のマイルストーン一覧/依存グラフ更新」の記述で、roadmap-of-roadmaps とは無関係。
- **根拠:** Reference 品質基準「該当箇所の位置情報が具体的・正確である」を逸脱している。文書内行番号参照は本来正確に書くべきで、ロールバック・改訂に伴うリンク腐敗を防ぐためには行番号でなくセクション名 (例: `intent-spec.md 「非スコープ」`) を採用するのが堅牢。
- **推奨アクション:** L564 の `(Intent Spec L41 / 制約)` を `(Intent Spec 「非スコープ」セクション)` または `(intent-spec.md L98)` に修正する。同様の行番号引用は本ファイルおよび他 SKILL でも将来的にセクション名参照に切り替えるのが望ましい (Retrospective 繰越候補)。
- **設計との関連:** Intent Spec 改訂前後で行番号がずれるリスクは本サイクルで実際に発生しており (`progress.yaml.rollbacks[0]` 参照)、L41 表記は改訂前の Intent Spec に対する参照が更新されないまま残った可能性が高い。

### #7 dev-roadmap/SKILL.md L88-100 の ASCII フローチャート: 4 行目以降の罫線が論理的に閉じていない

- **深刻度:** Minor
- **該当箇所:**
  - Commit: ffd2f3f (T1: dev-roadmap/SKILL.md 新設)
  - File: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`
  - Line: 89-100
- **問題の要約:** ワークフロー全体図 (ASCII):
  ```
  4. Roadmap Retrospective ─┘ (Gate: Main 判定)
                            │
                            ▼ ロードマップ完了
  ```
  4 行目で `┘` で右側を閉じているが、その下に縦線 `│` と矢印 `▼` が続いている。`┘` の意図は「右辺の流れを下に流す」だが、視覚的には「閉じた」ようにも見える。最低でも `┘` を `┴` または `├` に変えるか、4 と最終の「ロードマップ完了」を別ボックスとして書くと曖昧さが消える。
- **根拠:** Reference 品質基準「Mermaid 図の正確性 / 構文の正しさ・ノード接続の論理性」を ASCII 図にも適用すると、視覚的閉鎖と論理的継続が混在する。Mermaid 化するか、若干の罫線記号修正で改善可。
- **推奨アクション:** Mermaid `flowchart TB` に置換する (本サイクル全体で `graph LR` を採用しているため `graph TB` の方が一貫)、または ASCII を保つなら `┘` → `┤` に置換する形でループ閉鎖を意図しないことを明示する。
- **設計との関連:** design.md は本図を要求していないが、ユーザーへの可読性向上のために置かれた装飾図と推測される。

### #8 dev-roadmap/SKILL.md L275-291 の双方向参照 ASCII 図: ボックス幅の不揃い・縦線位置のずれ

- **深刻度:** Minor
- **該当箇所:**
  - Commit: ffd2f3f (T1: dev-roadmap/SKILL.md 新設)
  - File: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`
  - Line: 275-291
- **問題の要約:** 上下のボックスで罫線幅が一致していない。例えば上ボックス L275 `┌────...────┐` (53 文字) に対し、下ボックス L284 は `┌────...────┐` (53 文字) だが、内部行 L286-289 の最右列 `│` の位置がインデントとずれている (`docs/workflow/<identifier>/progress.yaml` 行は 50 文字で右 `│` が L284 と一致していない可能性)。さらに上ボックスの右下 `└──...──│──┘` で `│` が右端から 4 文字内側に挿入されているのは矢印起点を表現する意図と思われるが、矢印 `───────────┐` の終端と縦軸 `│` の論理位置が一致していない。
- **根拠:** Reference 品質基準「具体例の有無と図の正確性」を満たすには ASCII の罫線整列が要求される。可読性を損なう揺れを 1〜2 文字内に収めるなら許容範囲だが、コピー&ペースト時に等幅フォント以外で開くと崩れる可能性が増す。
- **推奨アクション:** 同等の情報を Mermaid 図 (例えば `graph LR; A[roadmap-progress.yaml] -->|workflow_identifiers| B[progress.yaml]; B -->|roadmap.id back-ref| A`) に置換する。または等幅検証して罫線位置を再整列する。
- **設計との関連:** design.md §「データフロー (`<roadmap-id>` ↔ `<identifier>` 双方向参照)」(L120-153) は既に Mermaid 図で同情報を提示しており、SKILL 側の ASCII 図は冗長気味。Mermaid 一本化で記述の一貫性が高まる。

### #9 dev-roadmap/SKILL.md L383-388 のディレクトリレイアウト Mermaid 図: ノードラベルが `roadmap-id-A` で prefix 重複の錯覚

- **深刻度:** Minor
- **該当箇所:**
  - Commit: ffd2f3f (T1: dev-roadmap/SKILL.md 新設)
  - File: `plugins/dev-workflow/skills/dev-roadmap/SKILL.md`
  - Line: 362, 384
- **問題の要約:** Mermaid 図内で `R1[roadmap-id-A/]` というラベルを使っており、その retrospective ノードが `RR1[roadmap-roadmap-id-A.md]` となる。`<roadmap-id>` のプレースホルダ的代用として `roadmap-id-A` を使ったため、`roadmap-` prefix を含む形になり、結果として retrospective ファイル名は「roadmap-`prefix +`roadmap-id-A`全体」で`roadmap-roadmap-id-A.md`という冗長表記となる。実運用では`<roadmap-id>`には`oauth-rollout` のような prefix を含まない名前が使われる想定 (本ドキュメントの命名ルールセクションでも例示されている)。
- **根拠:** Reference 品質基準「具体例の有無、良例 / 悪例の対比」を満たすには、サンプル ID として実運用に近い名前 (例: `oauth-rollout`) を使うほうが学習者に伝わりやすい。
- **推奨アクション:** ラベルを `roadmap-id-A` → `oauth-rollout`、`roadmap-roadmap-id-A.md` → `roadmap-oauth-rollout.md` に置換する。または、ジェネリック表記を保つなら `R1[<roadmap-id>/]`、`RR1[roadmap-<roadmap-id>.md]` のように `<>` で明示プレースホルダ化する。
- **設計との関連:** design.md には本図示は要求されておらず、SKILL 側の補助図。命名規則セクション (本 SKILL L411-414) では「`oauth-rollout`, `notification-platform`, `payment-modernization`」のような実例を挙げており、図内の例示と齟齬がある。

### #10 shared-artifacts/SKILL.md 成果物一覧テーブル: roadmap 系 4 行の `#` 列が `-` でソート不能

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 4244cb2 (T8: shared-artifacts/SKILL.md 拡張)
  - File: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
  - Line: 56-59
- **問題の要約:** roadmap 系 4 行は `#` 列に `-` を入れている (1〜12 の dev-workflow サイクル成果物と区別する意図と推測)。視覚的には区別効果があるが、`#` 列が「成果物の一意 ID」として機能する場合、後続で参照する際に「成果物 #14」という言い方ができず、参照困難。`-` のままだと将来 dev-roadmap 系成果物が増えた場合に通し番号も振れない。
- **根拠:** Reference 品質基準「テーブル構造が一貫している」「将来拡張可能」を逸脱気味。dev-workflow 系成果物と dev-roadmap 系成果物が同じテーブルに混在することの意味づけ (なぜ別表にしないか、なぜ通し番号を分けないか) が文書内で説明されていない。
- **推奨アクション:** 以下のいずれか:
  - 案 A: 通し番号を継続し 13〜16 を付与する (テーブル列の意味が「成果物の物理的順序」になる)。
  - 案 B: dev-roadmap 系を別テーブル (例: 「ロードマップ成果物一覧」) に分離する。
  - 案 C: `#` 列を削除し代わりに「Step / Phase」列を主キーにする (dev-workflow Step 1〜9 と dev-roadmap Step 1〜4 で重複しないため一意)。
- **設計との関連:** design.md §「既存スキルへの最小変更影響表」(L324) で「成果物一覧テーブル」追記が要求されているが番号付け方針は明示されていない。

### #11 dev-workflow/SKILL.md L763 のコミットメッセージ例「unlink milestone …」が誤解を招く可能性

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 6b6206b (T9: roadmap-progress.yaml 更新プロトコル追記)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Line: 762-764 (`(d) 更新時のコミット粒度` 内のコミットメッセージ例)
- **問題の要約:** サイクル完了時のコミットメッセージ例として「`docs(dev-workflow/<identifier>): unlink milestone <milestone-id> in roadmap <roadmap-id>`」が挙げられている。「unlink」は紐付けを解除する意味合いで読まれる可能性が高いが、本サイクル設計の動作は「紐付けは保持し、`milestones[].status` を `completed` に遷移させる」だけ (`workflow_identifiers[]` から削除しない、append-only 運用)。
- **根拠:** Reference 品質基準「コメントが『なぜ』を説明 (誤解を招かない)」に照らし、`unlink` は誤解を招く動詞。設計意図 (`active → completed` 遷移) を反映するメッセージとして `close milestone` / `complete milestone` / `mark milestone completed` が適切。
- **推奨アクション:** L763 の例を `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)` (design.md L297 の表記) に揃える。設計書 design.md L297 と SKILL の例文が異なっている点も解消できる。
- **設計との関連:** design.md L297 では「サイクル完了時の `roadmap-progress.yaml` 更新」のコミットメッセージ例として「`docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)`」と書かれており、本指摘が示すように SKILL の表記とずれている。

## 観点固有の評価項目 (documentation-quality)

| 評価軸                               | 評価                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 誤字脱字 / 文法                      | 大きな誤字は検出されず。日本語常体 (である調) で全体が統一されており敬体混入なし。プログラミング英文表記 (`graph LR`、`set semantics`) は適切に back-tick で囲まれている                                                                                                                                                                                               |
| タイポ (technical term / identifier) | `specialist-roadmap-*` / `roadmap-progress.yaml` / `<roadmap-id>` / `<milestone-id>` 等の identifier は全成果物で表記一貫している。`oauth-rollout` 例の prefix 混乱 (#9) と「unlink」の誤用 (#11) を除けば軽微                                                                                                                                                         |
| 冗長表現                             | 「最小限の責務」「紐付けだけできれば良い」「2 タイミングのみ」などの主旨はテンプレート / reference / SKILL で適切に重複明記されており、意図的な強調 (DRY 違反というより一貫性確保) と評価できる。dev-roadmap/SKILL.md L283-291 の ASCII 図と design.md の Mermaid 図は同情報の二重表現 (#8) で、Mermaid 統一が望ましい                                                 |
| 論理整合性                           | 段落間の論理的接続は適切。ただしステップ番号体系の混在 (#2)、旧ステップ番号の残置 (#1)、サイクル固有連番の流出 (#3) の 3 点で論理整合に綻びがある                                                                                                                                                                                                                      |
| reference 品質基準遵守               | references/roadmap.md / milestone.md / roadmap-progress-yaml.md / roadmap-retrospective.md は既存 reference の標準セクション (目的 / 作成者 / ファイル位置 / 各セクションの書き方 / 品質基準 / 関連成果物) を全て備えており、構造的整合性は高い。✅/❌ の対比表 (良例 / 悪例) も全 4 reference に存在                                                                  |
| template の placeholder              | `{{name}}` 形式で統一。templates/roadmap.md (30 種)、templates/milestone.md (29 種)、templates/roadmap-retrospective.md (47 種)、templates/roadmap-progress.yaml (テンプレート YAML 内コメント形式) が適切に分布している。プレースホルダ重複や欠落は検出されず                                                                                                         |
| Mermaid 図の正確性                   | `graph LR` で本サイクル全成果物が統一 (Research existing-skill-structure C-1 整合)。dev-roadmap/SKILL.md L359-396 の Mermaid 図は subgraph ネストと矢印接続が論理的に正しい。例示ラベルの prefix 重複 (#9) のみ Minor                                                                                                                                                  |
| 見出し階層                           | H1 → H2 → H3 → H4 の標準階層 (深すぎる H5 / H6 なし)。templates/roadmap-retrospective.md で H3 を 4 個並べる構造 (`roadmap 固有の改善案` 配下) は深すぎず適切                                                                                                                                                                                                          |
| 具体例の有無                         | references/roadmap.md と references/milestone.md は良例 / 悪例の表が存在 (各 6 行〜)。references/roadmap-progress-yaml.md は YAML サンプルブロックが含まれ、references/roadmap-retrospective.md は良例 ✅ 「マイルストーン M3 (decision-engine) は当初 1 サイクル想定だったが…」の具体エピソード例 (specialist-roadmap-retrospective-writer SKILL L113) との連携が良好 |

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                      | 修正コミット SHA                  |
| ----- | ------- | ----- | ----- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| 1     | 0       | 4     | 7     | 旧ステップ番号 (Step 8/9/10) 残置、ステップ番号付け不整合 (`4'` vs `5`)、サイクル固有「確定 N」流出、README 英日混在 | (未修正、Step 7 Round 1 完了時点) |

Round 2 以降が発生する場合は本セクションを更新する。

## 他レビューとの整合性

なし (Round 1 では他観点 reviewer の出力を参照しない、本観点は documentation-quality 単独で完結する範囲のみ評価)。

ただし Major #1 (旧ステップ番号残置) と #2 (ステップ番号付け不整合) は `holistic` 観点や `consistency` 観点 (本サイクルでプロジェクト固有観点として並列起動が想定されるなら) で重複検出される可能性が高い。重複した場合は、本観点では「記述品質の側面で誤情報が読者を混乱させる」根拠を、他観点では「設計整合性 / Intent Spec 充足の側面」を提示することで責務分離を維持する。重複時の優先度判断は Main に委ねる。

---

## Round 2 (post-Minor-fix re-review)

# Review Report: documentation-quality (Round 2)

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** documentation-quality
- **Reviewer:** reviewer-documentation-quality (Step 7 specialist instance, Round 2)
- **Reviewed at:** 2026-05-03T11:30:00Z
- **Scope:** Round 2 修正コミット 3 本 (`e01d03c`, `648e233`, `6eae32b`) で変更された全成果物 (`plugins/dev-workflow/` 配下スキル / template / reference / README、および `docs/workflow/2026-04-29-add-dev-roadmap-skill/` 配下のサイクル成果物のうち本ラウンドで修正された `validation-report.md` / `progress.yaml` / `design.md` / `intent-spec.md`)。Round 1 (8 件 = Major 4 / Minor 7、ただし計上ベースは Major 4 + Minor 7 = 11 件、本テーブル「サマリ」では 4 + 7 = 11) の解消確認 + Round 2 修正の波及問題 (新規発生) を主観点とする。サイクル進行中の `qa-design.md` / `manual-tests/` 等は本ラウンドの修正対象外なので Round 1 と同じく対象外、ただし Round 2 修正の影響で新たに整合性を逸脱した箇所があれば Minor として記録する。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 3    |

**Gate 判定:** `approved`

Blocker / Major は検出されず。Round 1 で計上した 11 件 (Major 4 / Minor 7) のうち **9 件が解消済**、**2 件が部分解消** (Minor #2 のリスト番号併存問題、Minor #11 の他ファイルとの表記不一致) で残存。新規発生の Minor は **3 件** (うち 2 件は Round 2 修正の取り残し、1 件は新規 inlining セクションの体裁) を検出。Round 1 の Major 4 件は全て解消されており、Step 7 進行可。

## Round 1 指摘の解消状況サマリ

| Round 1 # | 深刻度 | 内容 (要約)                                                                                               | Round 2 状況          | 修正コミット                                                                                                                                                                  |
| --------- | ------ | --------------------------------------------------------------------------------------------------------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1        | Major  | 旧 Step 8/9/10 残置 (`specialist-roadmap-retrospective-writer/SKILL.md` L135)                             | **解消済**            | `551e497` (T15 Major fix, Round 1.5)                                                                                                                                          |
| #2        | Major  | `dev-workflow/SKILL.md` ステップ番号 `4'` vs `5` 不整合                                                   | **部分解消**          | `551e497` で参照側 (L778) を `4'` に揃え一貫化したが、リスト番号 `5.` と自己ラベル `4'` の併存は残存                                                                          |
| #3        | Major  | サイクル固有「確定 N」が永続スキル / reference に流出 (planner SKILL L77 / roadmap-progress-yaml.md L149) | **解消済**            | `551e497`                                                                                                                                                                     |
| #4        | Major  | README.md 追記段落の英日不規則混在                                                                        | **解消済**            | `e01d03c`                                                                                                                                                                     |
| #5        | Minor  | `specialist-roadmap-retrospective-writer/SKILL.md` の `metadata.version` 欠落                             | **解消済 (方針転換)** | `648e233` で全 SKILL の `metadata.version` 削除統一                                                                                                                           |
| #6        | Minor  | `dev-roadmap/SKILL.md` L564 の `Intent Spec L41` 誤参照                                                   | **解消済**            | `648e233` (実際の文脈「非スコープ」セクション参照に置換)                                                                                                                      |
| #7        | Minor  | `dev-roadmap/SKILL.md` L88-100 ASCII フローチャートの罫線が論理的に閉じていない                           | **解消済**            | `648e233` (Mermaid `graph LR` 化)                                                                                                                                             |
| #8        | Minor  | `dev-roadmap/SKILL.md` L275-291 双方向参照 ASCII 図のボックス幅・縦線位置のずれ                           | **解消済**            | `648e233` (Mermaid `graph LR` 化)                                                                                                                                             |
| #9        | Minor  | `dev-roadmap/SKILL.md` L383-388 Mermaid 図のラベル `roadmap-id-A` の prefix 重複錯覚                      | **未解消**            | (Round 2 修正対象外、許容)                                                                                                                                                    |
| #10       | Minor  | `shared-artifacts/SKILL.md` 成果物一覧テーブル `#` 列の `-` (ソート不能)                                  | **解消済**            | `648e233` (13-16 連番に置換)                                                                                                                                                  |
| #11       | Minor  | `dev-workflow/SKILL.md` L763 の `unlink milestone` が誤解を招く                                           | **部分解消**          | `6eae32b` (`unlink → complete` 動詞の誤用は解消、ただし design.md L297 / `references/roadmap-progress-yaml.md` L144 の `close cycle with retrospective` 表記との不一致が残る) |

**集計:** 11 件中 9 件解消済 (うち 1 件は方針転換による解消) / 2 件部分解消 / 1 件未解消 (Round 2 修正対象外、Minor 許容範囲)。

## 指摘事項

### #1 `intent-spec.md` L128 / `qa-design.md` L101 の `metadata.version` 表記が SKILL 本体と不整合 (Round 2 取り残し)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `648e233` (T-Round2 M-1 / M-2 修正範囲)
  - File:
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md` L128
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md` L101 (TC-002 の検査文言)
- **問題の要約:** Round 2 修正 (M-1) で全 SKILL の `metadata.version` を削除し統一したにもかかわらず、本サイクル内のサイクル成果物 2 ファイルが旧仕様 (`metadata: { author, version }` / `metadata.version`) を引きずっている:
  - `intent-spec.md` L128: 「スキル frontmatter のスキーマは既存 `dev-workflow` 系スキルと同一 (name / description / metadata: { author, version })」 — `version` を含む規範的制約として記述。
  - `qa-design.md` L101 TC-002: 「`dev-roadmap/SKILL.md` が必要な frontmatter キーを保持する (name / description / metadata.author / metadata.version)」 — `metadata.version` を必須キーとして列挙。
  - 一方、`validation-report.md` SC-1 の観測値 (L26-37) は `name` / `description` / `metadata` の 3 キーで PASS 判定済 (= 実際は `metadata.version` を検査していない)。
- **根拠:** `progress.yaml.rollbacks[2].reason` (M-1) で「drop metadata.version from all SKILL.md (no longer needed, cleanup)」と明記されながら、根拠となる Intent Spec 制約 / QA 設計の検査文言が更新されておらず、**ドキュメント間で frontmatter 仕様の真のソースが二重化**している。Reference 品質基準「成果物間の整合性」を逸脱。Round 1 #5 が「方針転換による解消」となる過程で、Intent Spec / QA 設計の対応更新が漏れた。
- **推奨アクション:**
  - `intent-spec.md` L128 を「(name / description / metadata: { author })」に修正 (`version` を削除)。
  - `qa-design.md` L101 TC-002 の検査内容を「(name / description / metadata.author)」に修正、もしくは TC-002 の検査文言を validation-report.md 実装と揃えて `metadata` キー存在確認のみに簡素化。
  - 修正は機械的かつ Step 7 進行可否に影響しないため、Retrospective 繰越または Round 2.5 での軽微パッチが妥当。
- **設計との関連:** Round 1 #5 の解消アプローチ (方針転換による全削除) は妥当だが、Intent Spec 制約と QA 設計を真のソースとする一貫性が崩れた。Round 2 修正の波及範囲設定で `intent-spec.md` / `qa-design.md` を含めるべきだった。

### #2 `dev-workflow/SKILL.md` ステップ番号付け: リスト番号 `5.` と自己ラベル `4'` の併存が残存 (Round 1 #2 部分解消)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `551e497` (Round 1.5 で参照側を統一) / `648e233` (Round 2 で同範囲に変更なし)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L557 / L777
- **問題の要約:** Round 1 #2 で指摘した「ステップ番号付けが一貫しない (`4'` vs `5`)」について、Round 2 では参照側 (`roadmap-progress.yaml` 更新プロトコル L777 / `references/progress-yaml.md` / `references/roadmap-progress-yaml.md`) を全て **`ステップ 4'`** で統一する方向で修正した。これにより参照表記の一貫性は回復したが、L557 のリスト番号は依然 `5.` で、自己ラベルが「ステップ 4'」のため、**リスト番号 (`5.`) と自己ラベル (`4'`)** が同一段落内で食い違う構造が残る:

  ```
  4. progress.yaml を初期化 ... してコミット
  5. **roadmap 配下サイクルの場合の追加初期化** (ステップ 4'): ...
  6. Step 1 から着手する
  ```

  リストとして読むと「ステップ 5」なのに自己ラベルが「ステップ 4'」となるため、初見の読者は依然として「`4'` と `5` のどちらが正しい識別子か」迷う。

- **根拠:** Round 1 推奨アクション「案 A (L557 のラベル `(ステップ 4')` を削除し、L778 の参照表記 `ステップ 5` に揃える)」または「案 B (L557 を `4a.` のサブステップ表記にして全体を `4 / 4a / 5` に再編)」のいずれも採用されておらず、参照側だけを修正したため自己ラベルとリスト番号の不一致が永続化した。
- **推奨アクション:** Round 1 推奨アクションの案 A または案 B を改めて検討し、Retrospective 繰越または次サイクル軽微パッチで解消する。Round 1 で示した案のうち、**案 B (`4. progress.yaml 初期化 → 4a. roadmap 配下サイクル追加初期化 (新規) → 5. Step 1 着手` のサブステップ表記)** が既に修正された参照側 (`ステップ 4'` / `ステップ 4a` への置換) と整合しやすい。
- **設計との関連:** `design.md` L317 の挿入位置記述は実装 (L558) と整合済。本指摘はリスト体裁のみの問題で、内容・順序・依存性に影響しない。

### #3 `dev-workflow/SKILL.md` L792 のコミットメッセージ例が `design.md` L297 / `references/roadmap-progress-yaml.md` L144 と不一致 (Round 1 #11 部分解消)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `6eae32b` (M-7 修正)
  - File:
    - `plugins/dev-workflow/skills/dev-workflow/SKILL.md` L792
    - `docs/workflow/2026-04-29-add-dev-roadmap-skill/design.md` L297
    - `plugins/dev-workflow/skills/shared-artifacts/references/roadmap-progress-yaml.md` L144
- **問題の要約:** Round 1 #11 で指摘した「`unlink milestone` の動詞が誤解を招く」点について、Round 2 では SKILL.md L792 のみ `complete milestone <milestone-id> in roadmap <roadmap-id>` に修正された (動詞の誤用は解消)。しかし、design.md L297 と `references/roadmap-progress-yaml.md` L144 では完了時のコミットメッセージ例として `close cycle with retrospective (roadmap milestone <milestone-id> completed)` と書かれており、**SKILL の例文と design.md / reference の例文が別表記**になっている:
  - SKILL.md L792: `docs(dev-workflow/<identifier>): complete milestone <milestone-id> in roadmap <roadmap-id>`
  - design.md L297 / reference L144: `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)`

  両者は意味は同等 (どちらも「completed への遷移」を表す) だが、文字列としては別物で、ユーザー / 別 Specialist が「どちらを正規例とすればよいか」迷う。

- **根拠:** Round 1 推奨アクション「`docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)` (design.md L297 の表記) に揃える」は採用されず、新規動詞 `complete milestone` を SKILL 側だけに導入したため、設計書 / 書き方ガイドとの 3 ファイル間整合が崩れた。Reference 品質基準「成果物間の表記一貫性」を逸脱。
- **推奨アクション:** 以下 2 案のいずれか:
  - **案 A (推奨、Round 1 で提案された)**: SKILL.md L792 を `docs(dev-workflow/<identifier>): close cycle with retrospective (roadmap milestone <milestone-id> completed)` に揃える。design.md / reference は変更不要。
  - **案 B**: design.md L297 / reference L144 を `docs(dev-workflow/<identifier>): complete milestone <milestone-id> in roadmap <roadmap-id>` に揃える。
- **設計との関連:** Round 1 #11 で「設計書 design.md L297 と SKILL の例文が異なっている点も解消できる」と推奨アクションで明記されていたが、この一致部分が未対応のまま残った。Retrospective 繰越または軽微パッチで解消可。

## 観点固有の評価項目 (documentation-quality)

| 評価軸                               | Round 2 評価                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 誤字脱字 / 文法                      | Round 2 修正による誤字脱字の混入なし。日本語常体は維持。Mermaid 図変換に伴う `&lt;` / `&gt;` / `&#91;` / `&#93;` の HTML エンティティ使用は構文上正当 (`graph LR` 内のラベル `[<milestone-id>.md]` を `&lt;milestone-id&gt;.md` でエスケープ)                                                                                                                                                                                                                                                                                                                                                          |
| タイポ (technical term / identifier) | identifier (`<roadmap-id>` / `<milestone-id>` / `<identifier>`) の表記は Round 2 修正後も全成果物で一貫。新規問題なし                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 冗長表現                             | Round 2 で `validation-evidence/` 4 ファイル (合計 104 行) を `validation-report.md` の「検証ログ (インライン)」セクションに集約したことで、サイクル進行中ドキュメントの冗長性 (2 場所での同一情報) は解消した。プラグイン側汎用 SKILL の `validation-evidence/` 言及 (specialist-validator/SKILL.md, references/validation-report.md, templates/validation-report.md, dev-workflow/SKILL.md L134/L496/L502/L711, specialist-common/SKILL.md, shared-artifacts/SKILL.md L137) は「大きな証拠が必要な場合のみ」の汎用規定として残存しており、本サイクルでのインライン化方針と矛盾しないため新規指摘なし |
| 論理整合性                           | Round 1 で指摘された 3 大論理整合課題 (旧ステップ番号 / `4'` vs `5` / サイクル固有「確定 N」) のうち 2 件 (#1 / #3) が解消、1 件 (#2) が部分解消。新たに「frontmatter スキーマ規範の二重化」(本ラウンド #1) が発生したため、論理整合の総合評価は Round 1 と比べ若干向上 (Major 0 / Minor 3 件分の整合課題のみ残存)                                                                                                                                                                                                                                                                                     |
| reference 品質基準遵守               | references/roadmap-progress-yaml.md の「サイクル固有連番」流出が解消 (Round 1 #3)。Round 2 で reference 側の修正は最小限に留まったため、本ラウンドの reference 自体への新規指摘なし                                                                                                                                                                                                                                                                                                                                                                                                                    |
| template の placeholder              | `templates/validation-report.md` 内の `validation-evidence/` 言及は汎用規定として残存。本サイクルでインライン化したことで「テンプレート vs 実装」のずれが生じうるが、本サイクルは特殊事例 (小規模、エビデンスがインラインで完結) であり、テンプレート側を変更する必要はなし。新規問題なし                                                                                                                                                                                                                                                                                                              |
| Mermaid 図の正確性                   | dev-roadmap/SKILL.md L88-102 (ワークフロー全体図) と L276-289 (双方向参照図) が `graph LR` の Mermaid に変換され、矢印の論理的接続 (`-->` / `-.->`) も正確。subgraph ラベル / ノード ID は構文準拠 (HTML エンティティで `<>` / `[]` をエスケープ)。Round 1 #7 / #8 / #9 の 3 件のうち #7 / #8 は解消、#9 (`roadmap-id-A` prefix 重複の錯覚) は Round 2 修正対象外で残存だが、Mermaid 図自体の正確性には影響しないため新規指摘なし                                                                                                                                                                      |
| 見出し階層                           | Round 2 修正後も H1 → H2 → H3 → H4 の標準階層を維持。validation-report.md L312 「## 検証ログ (インライン)」が新規 H2 セクションとして適切に追加され、その配下 L316/L335/L356/L365/L383 が H3 で階層化されている                                                                                                                                                                                                                                                                                                                                                                                        |
| 具体例の有無                         | Round 1 で評価した具体例の質は維持。Round 2 で validation-report.md インラインセクションに 4 種類の証拠ログ (SC-12 baseline diff / SC-13 specialist enumeration / SC-7-9 grep counts / TC-015 YAML parse) が直接埋め込まれ、コードブロック内の出力サンプルが具体的になり可読性が向上                                                                                                                                                                                                                                                                                                                   |

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                                                    | 修正コミット SHA                                    |
| ----- | ------- | ----- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 1     | 0       | 4     | 7     | 旧ステップ番号 (Step 8/9/10) 残置、ステップ番号付け不整合 (`4'` vs `5`)、サイクル固有「確定 N」流出、README 英日混在                               | `551e497`, `e01d03c` (Round 1.5 / Round 2 部分修正) |
| 2     | 0       | 0     | 3     | Round 1 指摘 9 件解消 / 2 件部分解消 / 1 件未解消 (許容)。新規 Minor 3 件 (frontmatter 仕様の二重化、リスト番号併存、コミットメッセージ表記不一致) | `648e233`, `6eae32b`, `e01d03c`                     |

Round 3 以降が発生する場合は本セクションを更新する。本ラウンド時点では Blocker 0 件 / Major 0 件のため Step 7 → Step 8 / 9 (またはサイクル完了) 進行可。Minor 3 件は Retrospective の材料として記録し、機械的修正可能なものは次サイクル軽微パッチで解消することを推奨。

## 他レビューとの整合性

Round 2 では本観点 (documentation-quality) のみ単独再レビューのため、他観点 reviewer との直接整合確認は行わない。Round 1 で同時並列実行された `holistic` / `consistency` / `backward-compatibility` の指摘との重複可能性:

- **本ラウンド #1 (frontmatter スキーマ規範の二重化)**: `consistency` 観点で扱われる可能性高 (Round 1 review/consistency.md L92, L179 で同等の議論がされていた)。Round 2 で SKILL 本体は統一され Round 1 consistency #1 は解消したが、Intent Spec / QA 設計の規範文言は更新漏れで本ラウンドで再浮上。`consistency` 観点の Round 2 再レビューが行われる場合は同件が両観点で重複検出される見込み
- **本ラウンド #2 (リスト番号併存)**: `consistency` 観点で重複検出されうる。本観点では「読者の混乱可能性 = 記述品質」、`consistency` 観点では「番号体系の整合性」として責務分離可能
- **本ラウンド #3 (コミットメッセージ表記不一致)**: `consistency` 観点と重複可能性高。本観点では「読者が正規例として参照する際の混乱」を、`consistency` 観点では「3 ファイル間の表記統一性」を問う形で責務分離可能

重複した場合の優先度判断は Main に委ねる。
