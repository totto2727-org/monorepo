# Research Note: description-compression

- **Identifier:** 2026-04-29-retro-cleanup
- **Topic:** description-compression
- **Researcher:** researcher (Step 2 並列インスタンス)
- **Created at:** 2026-04-29T15:10:00Z
- **Scope:** 9 specialist (`specialist-{intent-analyst,researcher,architect,qa-analyst,planner,implementer,reviewer,validator,retrospective-writer}`) + 補助的に `specialist-common` および `agents/*.md` の frontmatter `description` の現状文字数測定、構成内訳分析、共通テンプレート化に向けた圧縮余地特定。本文・本ロジックは対象外。

## 調査対象

Intent Spec L51 / L72-L77 / 成功基準 #7-#15 (L169-L177) で求められている「各 specialist description ≤ 700 文字」を達成するため、以下を調査する:

1. 9 specialist + `specialist-common` の `SKILL.md` frontmatter `description` の**実測文字数** (改行込み / 改行除き / バイト数) を確定
2. Intent Spec L76 に記載された「現 733 / 767 / 897 / 1150 / 1093 / 740 / 1018 / 1297 / 709」が文字数なのかバイト数なのかを検証
3. 各 description の構成（1 行サマリ / 起動トリガー / Do NOT use for）ごとの文字数内訳
4. 圧縮可能な冗長表現の特定（共通プレフィクス、specialist-\* 名の長文列挙など）
5. 700 字以下に収める共通テンプレート骨格の提案（サマリ / トリガー / Do NOT の文字数配分）
6. `agents/*.md` の `description` との同期状態（Step 番号・キーワードの整合性）
7. `ai-dlc` キーワードが `dev-workflow` リネーム後に残存していないかの最終確認

Intent Spec の成功基準 #7-#15 はファイル単位の閾値判定のみであり、本 Research Note は Step 3 architect が共通フォーマットを確定できる粒度まで掘り下げる。

## 発見事項

### F1. 「文字数」と「バイト数」の単位齟齬 (重要)

Intent Spec L76 / L169-L177 の「現 733 / 767 / 897 / 1150 / 1093 / 740 / 1018 / 1297 / 709」は **UTF-8 バイト数 (`gwc -c`)** に近い値であり、**文字数 (`gwc -m`)** ではない。実測すると以下のとおり差が出る:

| ファイル                                   | 文字数 (改行込) | 文字数 (改行除) | バイト数 (改行込) | Intent Spec L76 記載 |
| ------------------------------------------ | --------------- | --------------- | ----------------- | -------------------- |
| `specialist-architect/SKILL.md`            | 410             | 403             | 748               | 733                  |
| `specialist-implementer/SKILL.md`          | 424             | 417             | 782               | 767                  |
| `specialist-intent-analyst/SKILL.md`       | 538             | 530             | 914               | 897                  |
| `specialist-planner/SKILL.md`              | 689             | 678             | 1173              | 1150                 |
| `specialist-qa-analyst/SKILL.md`           | 609             | 598             | 1116              | 1093                 |
| `specialist-researcher/SKILL.md`           | 405             | 398             | 755               | 740                  |
| `specialist-retrospective-writer/SKILL.md` | 577             | 567             | 1039              | 1018                 |
| `specialist-reviewer/SKILL.md`             | 732             | 720             | 1322              | 1297                 |
| `specialist-validator/SKILL.md`            | 394             | 387             | 724               | 709                  |
| `specialist-common/SKILL.md` (参考)        | 775             | 763             | 1301              | 1276                 |

Intent Spec の数値とのズレ (-15 ～ -25 バイト) は YAML スカラ折り返しのインデント (`  ` = 2 byte/行) を含めるかどうかの差と思われる。**いずれにせよ「文字数」基準では現状すでに 9 specialist 中 8 個が 700 文字以下** (`gwc -m` 改行込み)。700 を超えるのは `specialist-reviewer` (732) のみ。

### F2. 単位ベンチマーク: 文字数か、バイト数か

Claude Code の skill discovery エンジンが内部で何を見ているかは公開仕様がないが、`description` の容量制約は**文字数**で議論されることが慣例的に多い (Anthropic SDK の system prompt size 等も token / character 寄りの議論)。Intent Spec の成功基準 #7-#15 は「現 733 / 740 / 767 / 897 / 1018 / 1093 / 1150 / 1276 / 1297」を「現状」として 700 以下を目指すという書き方で、暗黙的に**バイト数**を成功基準として採用している。Step 3 architect で**「成功基準は UTF-8 バイト数で計測する」と単位を確定する必要あり**（さもなくば実装者が `wc -m` で測ってしまい、過剰圧縮または基準の取り違えを起こす）。

### F3. description のセクション内訳 (改行除き文字数 / バイト数)

各 description は概ね「① 1 行サマリ」「② 起動トリガー」「③ Do NOT use for」の 3 部構成。実測内訳:

| Skill                           | サマリ chars/bytes | トリガー chars/bytes | Do NOT chars/bytes | バイト合計 (改行除く近似) |
| ------------------------------- | ------------------ | -------------------- | ------------------ | ------------------------- |
| specialist-architect            | 178/290            | 81/203               | 142/246            | 739                       |
| specialist-implementer          | 159/291            | 81/199               | 175/283            | 773                       |
| specialist-intent-analyst       | 159/293            | 91/197               | 278/414            | 904                       |
| specialist-planner              | 312/532            | 138/258              | 226/370            | 1160                      |
| specialist-qa-analyst           | 261/504            | 121/237              | 214/362            | 1103                      |
| specialist-researcher           | 164/314            | 79/195               | 153/237            | 746                       |
| specialist-retrospective-writer | 227/413            | 141/255              | 197/359            | 1027                      |
| specialist-reviewer             | 359/625            | 199/435              | 160/248            | 1308                      |
| specialist-validator            | 162/296            | 78/194               | 145/225            | 715                       |
| specialist-common (参考)        | 292/508            | 98/236               | 340/454            | 1198                      |

**観察:**

- **トリガー** (起動トリガー) は **194-258 byte / 78-141 char** に収まり、reviewer 以外はほぼ均一。圧縮余地は少ない。
- **Do NOT** はバラつきが大きく **225-435 byte**。特に `specialist-intent-analyst` (414 byte / 278 char) と `specialist-reviewer` の旧文言は specialist-\* 名を 6 個以上列挙するため肥大化しがち。
- **サマリ** (1 行サマリ) は **290-625 byte** とさらにバラつきが大きく、**`specialist-reviewer` (625 byte) と `specialist-planner` (532 byte) と `specialist-qa-analyst` (504 byte) が突出**。これらが 700-byte 超過の主因。

### F4. 700 byte 超過 specialist の超過原因

| Skill                           | 超過 byte | 主因                                                                                                                                       |
| ------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| specialist-architect            | +48       | サマリのトリガー以外の説明と Do NOT の `specialist-*` 名列挙が冗長 (4 箇所)                                                                |
| specialist-implementer          | +73       | Do NOT に「複数タスクを単一 implementer で実装（タスクごとに別インスタンス）」という当該役割固有の禁止事項が長文                           |
| specialist-intent-analyst       | +204      | Do NOT に他 8 specialist 名 + dev-workflow を列挙 (414 byte)                                                                               |
| specialist-planner              | +460      | サマリにテスト設計の責務分離説明 (qa-analyst との関係) を 3 文 (175 byte 程度) 含む / Do NOT も具体的すぎる                                |
| specialist-qa-analyst           | +403      | サマリに「実行主体 × 検証スタイル」「Vitest / Playwright 等」など実装ヒントを 504 byte 包含 / Do NOT も specialist 名 4 個列挙             |
| specialist-researcher           | +46       | サマリは 314 byte で許容内、ただし Do NOT にも観点範囲外注意 + specialist 名 3 個                                                          |
| specialist-retrospective-writer | +327      | サマリと Do NOT で「成果物・progress.yaml・TODO.md・ループ履歴」など列挙 / Do NOT に CLAUDE.md 直接書き込み禁止など細部が混入              |
| specialist-reviewer             | +608      | **最大の超過**。サマリで 6 観点を 1 つずつ列挙 + holistic 観点の責務 2 文 (合計 625 byte) / トリガーも観点キーワードを 6 個列挙 (435 byte) |
| specialist-validator            | +24       | わずかに超過。Do NOT を 1 項目減らせば収まる                                                                                               |

### F5. 共通の「冗長プレフィクス」「冗長サフィクス」が観測される

- **共通プレフィクス**: `[Specialist 用] dev-workflow Step N (XXX) を担当する専門エージェント YYY の作業詳細。` という骨格は 9 件中 8 件で同一 (specialist-common のみ「[Specialist 背景基盤 / 役割固有スキルから参照される前提ルール集]」と異なる)。**「専門エージェント YYY の作業詳細」は冗長で、`Step N (XXX) — YYY` などの省略表記で 30-50 byte 削減可能**。
- **共通サフィクス・トリガー**: `起動トリガー: Main が YYY エージェントをサブエージェントとして起動した際、または ユーザーが明示的に <X> を依頼した場合。` も 8 件で同一構造。「Main が YYY をサブエージェントとして起動した際、またはユーザーが <X> を依頼した場合」は約 100 byte 取る固定文だが、**テンプレート化すれば各 specialist の差分は `<YYY>` と `<X>` のみとなり管理コスト低**。
- **共通サフィクス・Do NOT**: `Do NOT use for: <list>。` の `<list>` が他 specialist 名の長大列挙になっており、**重複** (intent-analyst の Do NOT に並ぶ 8 specialist は **specialist-common との重複**) が発生している。Do NOT で他 specialist 名を全列挙する必要は低く、「他 Specialist の領域 (調査 / 設計 / 実装 / 検証 / 振り返り)」のように汎用化すれば 100-150 byte 削減可能。

### F6. 共通テンプレート骨格の試算

700 byte 以下を全 9 specialist で統一達成するための骨格 (バイト数想定):

```yaml
description: >
  [Specialist 用] dev-workflow Step N (<Phase>) を担当。
  <1-2 文の役割サマリ>。<並列起動の有無 / 1 インスタンス = 1 ユニット の単位>。
  起動トリガー: Main が <agent-name> をサブエージェント起動した際、またはユーザーが
  "<keyword 1>" / "<keyword 2>" を依頼した場合。
  Do NOT use for: 他 Specialist の領域 (調査 / 設計 / 実装 / 検証 / 振り返り)、
  <この specialist 固有の禁止事項を 1-2 項目>。
```

文字数配分の目安 (合計 700 byte):

| 部分                           | 配分 byte  | 配分 char (日本語混在 ≒ byte/2) |
| ------------------------------ | ---------- | ------------------------------- |
| 1 行サマリ (役割 + 単位)       | ≤ 320 byte | ≤ 160 char                      |
| 起動トリガー (Main + ユーザー) | ≤ 220 byte | ≤ 110 char                      |
| Do NOT use for                 | ≤ 160 byte | ≤ 80 char                       |

実測値と照合すると:

- **architect / implementer / researcher / validator** はこの骨格でほぼそのまま 700 byte 以下に収まる (現状既に 715-782 byte なので 20-80 byte の削減で達成)
- **intent-analyst / retrospective-writer** は Do NOT 列挙の汎用化で 200 byte 程度削減し 700 以下に収まる
- **planner / qa-analyst / reviewer** はサマリ自体の整理が必要 (固有の責務分離説明・観点列挙を本文に逃がす)

### F7. agents/\*.md との同期状態

`agents/*.md` (9 件) の description はすべて 150-460 char / 312-846 byte と SKILL.md より短い。Step 番号・「サブエージェントとして起動する」などの表現は完全一致しているが、**フォーマットがバラバラ**:

- `agents/reviewer.md` `agents/validator.md` `agents/retrospective-writer.md` のみ Do NOT 句あり (短縮版)
- 他の 6 件は Do NOT 句が無く、サマリ + 並列性のみ
- agents/\*.md の Step 番号と SKILL.md の Step 番号は完全一致 (Step 1-9 の 9 Specialist 構成、validator=Step 8, retrospective-writer=Step 9 など)

`agents/*.md` 側の description は既に 700 byte 以下に収まっており本サイクルでは**追加圧縮は不要**だが、Step 3 architect で「SKILL.md description は agents/\*.md description のスーパーセット」というルールを明確化できれば管理が容易になる。

### F8. ai-dlc キーワード残存状況

`ggrep -rn -i 'ai[-_]dlc' plugins/dev-workflow/` の結果は **README.md L21 / L23 / L27 のみ 3 件**。すべて「AI-DLC とは別物である」という差別化の文脈での意図的言及であり、削除対象ではない:

- L21: `inspiration from ... AI-DLC. It is **not** an implementation, derivative, or variant of AI-DLC.`
- L23: `... independent method (rather than an AI-DLC derivative) is recorded in ...`
- L27: `Implementing AI-DLC compatibility or parity.` (非ゴール)

スキル description / agents description / specialist-\* 本文には ai-dlc キーワード残存なし。Intent Spec L107 の前提どおり。

### F9. SKILL.md description と本文「役割」セクションの責務分離

`specialist-researcher/SKILL.md` 等を見ると、description には「観点ごとに並列起動される前提」のような**運用情報**まで含まれているが、これは本文「## 役割」「## 担当範囲」セクションでも記述されている。**運用情報を本文に集約し、description は「skill discovery のためのキーワード密度最大化」に専念する**方針が Step 3 architect 検討の余地あり。

## 引用元

- Intent Spec: `docs/dev-workflow/2026-04-29-retro-cleanup/intent-spec.md:L51` (description ≤ 700 文字目標) / `:L72-L77` (圧縮方針) / `:L169-L177` (成功基準 #7-#15)
- 各 specialist SKILL.md frontmatter: `plugins/dev-workflow/skills/specialist-architect/SKILL.md:L1-L13`, 同 `specialist-common:L1-L21`, `specialist-implementer:L1-L13`, `specialist-intent-analyst:L1-L14`, `specialist-planner:L1-L17`, `specialist-qa-analyst:L1-L18`, `specialist-researcher:L1-L13`, `specialist-retrospective-writer:L1-L16`, `specialist-reviewer:L1-L18`, `specialist-validator:L1-L13`
- 各 agents/\*.md frontmatter: `plugins/dev-workflow/agents/{architect,implementer,intent-analyst,planner,qa-analyst,researcher,retrospective-writer,reviewer,validator}.md:L1-L8`
- ai-dlc 残存件数: `plugins/dev-workflow/README.md:L21,L23,L27` (3 件、すべて意図的差別化記述)
- 計測コマンド出力: 本 Research Note 作成時に `gawk` + `gwc -c` (バイト数) / `gwc -m` (文字数) で実測

## 設計への含意

Step 3 architect が design.md を起こす際、以下の判断材料として直接利用可能。

### I1. 成功基準の単位を「UTF-8 バイト数」と確定すべき

Intent Spec L169-L177 の「700 文字以下」は UTF-8 バイト数で運用するのが適切（記載値が `gwc -c` 寄りのため）。Step 3 architect は design.md または qa-design.md に「`gwc -c` で measure する」と機械検証ルールを明示し、validator が再現可能にする。混乱を避けるため Intent Spec 自体の文言は変えず「成功基準計測コマンドは `gwc -c`」と運用ルールで補強する。

### I2. 共通テンプレート骨格を design.md で確定する

F6 で示した骨格 (1 行サマリ ≤ 320 byte / トリガー ≤ 220 byte / Do NOT ≤ 160 byte = 合計 ≤ 700 byte) を Step 3 architect が確定し、9 specialist 全件に同一骨格を適用する。これにより:

- 全 specialist description を機械的に validate 可能 (各セクション境界が明確)
- 将来 Specialist 追加時に description 形式が自動的に統一される
- agents/\*.md description は SKILL.md description のサマリ部分のみを再利用するルール化で同期コスト低減

### I3. specialist-reviewer は本文への責務移動が不可避

reviewer のサマリ (625 byte) は 6 観点列挙 + holistic 観点の責務記述で構成されているが、**6 観点の名前と holistic の責務は本文「## 役割」セクションに既に記述されている**。description では「観点別に 6 並列、うち 1 観点が holistic で全体整合性を担う」程度に縮約し、観点リストは本文に逃がすべき。圧縮目標: 625 → 250 byte (375 byte 削減)。

### I4. specialist-intent-analyst の Do NOT は汎用化で大幅縮約可能

現状 414 byte の Do NOT はほぼ全 specialist 名 + dev-workflow を列挙しているが、これは specialist-common が同様の列挙を持つため**重複**。Step 3 architect で「他 Specialist の領域 (調査 / 設計 / 実装 / レビュー / 検証 / 振り返り)」など 5-6 単語のカテゴリ列挙に置換する方針を採用すれば、200 byte 程度に圧縮可能 (-200 byte 削減)。

### I5. specialist-planner / qa-analyst のサマリ簡略化

`planner` のサマリには「テスト設計は Step 4 (QA Design) の qa-analyst が担当」という責務境界の明示があるが、これは本文「## 役割」と重複しており description からは外せる (-150 byte)。同様に `qa-analyst` の「Vitest / Playwright 等に依存しない抽象レベル」は本文に既述で description からは「テストフレームワーク非依存」程度に短縮できる (-100 byte)。

### I6. agents/\*.md description は SKILL.md description の派生として位置付ける

F7 のとおり agents/_.md は 312-846 byte と既に小さく、Step 3 architect で「agents/_.md description = SKILL.md description のサマリ部分のみ + Do NOT 1 行」のルール化を検討すれば、SKILL.md 修正時に agents/_.md も連動して機械的に再生成できる (本サイクルでは agents/_.md は触らない可能性が高いが、将来のメンテ容易性向上)。

### I7. ai-dlc キーワードは本サイクルの作業対象外で確定

F8 のとおり残存は README.md の差別化記述 3 件のみで、削除すると逆に「AI-DLC との関係性」の説明が失われ readers に対する透明性を損なう。Intent Spec L141 の「既に解消済み `ai-dlc` キーワード衝突」と整合し、本サイクルでは**触らない**方針で固定する。

### I8. specialist-common description の扱い (Intent Spec L77 留保事項)

specialist-common description は現 1301 byte / 775 char。Intent Spec L77 で「specialist-common は他 specialist 本文から参照される設計のため、description は他より緩い制約で良いか」が未解決事項として留保されている。F3 の内訳を見ると、specialist-common の Do NOT (454 byte) は他 9 specialist 名 + dev-workflow を全列挙しており、最も冗長。**他 specialist と同じ骨格 (≤ 700 byte) に揃える方が一貫性は高いが、specialist-common は trigger condition で発火する必要がない (本文参照のみ) ため、800 byte 程度を許容しても実害は無い**。Step 3 architect で要決定。

## 残存する不明点

### Q1. Claude Code skill discovery の description 容量上限実測値

Anthropic 公式に「description の最大文字数」「token 化の挙動」が公開されていないため、700 byte が安全マージンかどうかは検証不可。実機ドッグフード (次サイクル) でのみ判明する。本サイクルでは Intent Spec の「700 byte 以下」をそのまま受け入れる前提で進める。

### Q2. agents/\*.md description を本サイクルで圧縮対象に含めるか

Intent Spec L72-L77 / 成功基準 #7-#15 は SKILL.md のみを成功基準として明記し、agents/_.md は明示的に対象に含まれていない。F7 のとおり既に小さいため対象外で問題ないと判断するが、\*\*Step 3 architect で「agents/_.md は本サイクル非スコープ」を明文化することを推奨\*\*。

### Q3. specialist-common description の閾値設定

I8 で述べたとおり 700 byte / 800 byte / 制約なし の 3 案あり。Step 3 architect でユーザー判断 (Main 経由) を仰ぐか、design.md で「800 byte 許容」と暫定確定するかの 2 ルートが存在する。

### Q4. description 修正時の機械置換戦略

Intent Spec L209 の「gsed `-e` 連鎖禁止 / 2-phase placeholder」ルールは本サイクルの implementer に適用される。**9 specialist の description を一斉置換する場合、各 SKILL.md ごとに個別に gsed 実行するか、共通の placeholder 戦略を取るかは Step 5 planner が task-plan.md で決定**。description は specialist ごとに固有の文言を含むため、`__SRK_DESC_<n>__` 方式の placeholder が機能しにくい (むしろ各 specialist は新規 description を直接 Write する方が安全)。Step 3 / 5 でこの方針を design.md / task-plan.md に明記すべき。

### Q5. F2 で指摘した「文字数 vs バイト数」の単位齟齬を Intent Spec に反映するか

Intent Spec の文言を変えるのは specialist-intent-analyst の領分のため、本サイクル中での変更可否は Main の判断。**design.md レベルで「成功基準計測単位 = UTF-8 バイト数 (`gwc -c`)」と注釈すれば Intent Spec 本体は変更不要**で、実装誤差を防げる。
