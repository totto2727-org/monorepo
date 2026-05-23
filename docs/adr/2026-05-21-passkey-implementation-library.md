---
confirmed: true
scope: general
---

# ADR: Passkey 実装ライブラリ選定

- **Filed at:** 2026-05-21
- **Filer:** implementer (Step 6)
- **Originating step:** dev-workflow Step 6 (Implementation) of cycle `feed-platform-ms-02-passkey-magic-link`
- **Storage path:** docs/adr/2026-05-21-passkey-implementation-library.md

## Status

`Accepted` — ms-02 (`feed-platform-ms-02-passkey-magic-link`) で確定。Passkey / WebAuthn の実装方式は `identity-provider` 内に閉じるが、`identity-provider` 自体が **汎用認証基幹サーバ** (ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` D-4) であるため、本リポジトリで認証認可を要する将来の他システムにも影響する。このため General mode (`docs/adr/`) に配置し、`scope: general` で保存する。

## Context

ms-02 で `identity-provider` に Passkey 認証を実装する必要が生じた。Better Auth は既に採用済 (ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` D-1 を実現する具体技術として、ms-02 で導入確定) であり、認証基盤本体としては Better Auth が運用される前提が存在する。

その上で、Passkey / WebAuthn レイヤの実装方式を決定する必要があった。Passkey は WebAuthn 仕様に準拠する必要があり、credential 登録 / 認証 (assertion 検証) / public key 永続化 / device meta (backed_up / device_type 等) の管理が要件となる。これらを **Better Auth に統合された plugin として実装するか / 別の standalone WebAuthn ライブラリで自前実装するか / 完全な custom 実装にするか** の選択肢を比較する必要がある。

本決定は `identity-provider/app/feature/auth/better-auth.ts` における Passkey 関連の依存ライブラリ選定として実装に直結し、また後続マイルストーンが Passkey 関連機能 (例: device 管理 UI / Passkey の追加・削除フロー) を拡張する際の前提となる。

## Decision

Better Auth の公式 `passkey` plugin (`@better-auth/passkey`) を採用する。

### 採用理由

- **Better Auth 本体に統合済み**: `betterAuth({ plugins: [passkey({...})] })` の宣言のみで認証フローに組み込める。認証本体 (session / account / user) と Passkey credential の永続化が同一 Better Auth エコシステム内で一貫管理される
- **DB schema 自動管理**: `passkey` テーブル (fields: `credential_i_d` / `public_key` / `backed_up` / `device_type` / `user_id` / `created_at` 等) を Better Auth が自動生成 / migration する。schema drift を最小化できる
- **Effect Service 統合容易**: Better Auth instance を構築する factory (`makeInstance`) 内に plugin として組み込むだけで完結し、`identity-provider` の Effect Layer 構造に追加の Service 抽象を導入する必要がない
- **別途 WebAuthn ライブラリ不要**: WebAuthn の challenge 生成 / attestation 検証 / assertion 検証は plugin 内部で完結し、SimpleWebAuthn 等の追加依存を導入する必要がない
- **rp_id / origin / rpName を config 経由で注入可能**: `passkey({ rpID, origin, rpName })` で環境差分 (dev / staging / prod) を `Env` Service から伝播できる

### 候補比較

| Option          | Summary                                                                                                                                  | Adopted / Rejected | Rationale                                                                                                                                                                       |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | Better Auth `passkey` plugin (`@better-auth/passkey`)                                                                                    | Adopted            | Better Auth 本体に統合済み / DB schema 自動管理 / 追加 WebAuthn ライブラリ不要 / Effect Layer への組み込みが宣言的                                                              |
| **B**           | SimpleWebAuthn (standalone WebAuthn ライブラリ) を直接利用し、credential 永続化 / challenge 管理 / Better Auth との橋渡しを自前実装       | Rejected           | WebAuthn 低レベル API への直接依存により実装量が増大 / Better Auth session との連携を自前で書く必要 / passkey table schema も自前定義になり Better Auth の auto-migration と齟齬が生じる |
| **C**           | WebAuthn 仕様 (`navigator.credentials` + サーバ側検証) を完全 custom 実装                                                                | Rejected           | attestation / assertion 検証のセキュリティリスクを内製する / メンテナンスコスト過大 / Passkey 仕様改訂への追従負荷                                                              |

## Consequences

### Newly added

- **`@better-auth/passkey` への依存確定**: `identity-provider` の `package.json` に `@better-auth/passkey` が追加され、Better Auth instance の plugin 配列に `passkey({...})` が組み込まれる
- **`passkey` テーブルが Better Auth 管理下に**: schema 定義 (fields マッピング) は `better-auth.ts` 内の `passkey` plugin config で完結し、Atlas / Kysely 経由の手動 schema 管理は不要 (Better Auth の auto-migration が SoT)
- **rp_id / origin の Env 依存**: `PASSKEY_RP_ID` / `BASE_URL` が Env Service 経由で plugin に注入され、これらの値が Better Auth config の一部として Passkey の信頼境界を構成する

### Existing impact

- **ADR `2026-05-05-...` D-1 (4 構成要素)** との整合: Passkey credential は `identity-provider` (= 基幹サーバ) の DB に格納され、リソースサーバ側 (`feed-platform-backend`) は Passkey の存在を意識しない (JWT 検証のみ)。本 ADR は D-1 の責務分担に従う
- **将来の他システムへの影響**: `identity-provider` を再利用する将来の他システムも、Passkey 認証を必要とする場合は本 ADR の選定 (Better Auth `passkey` plugin) を引き継ぐ。独立した WebAuthn 実装を起こす必要はない

### Constraints going forward

- **`identity-provider` から Better Auth を切り離す場合は migration 必須**: Passkey credential 永続化形式が Better Auth `passkey` plugin schema に紐づくため、認証基盤を Better Auth から別実装に置き換える際は credential データの schema 変換 / 再登録フローが必要となる
- **WebAuthn の細かい振る舞いは plugin 実装に依存**: attestation 検証の厳格度 / supported algorithms / counter ハンドリング等は Better Auth plugin の内部実装に従う。挙動変更が必要な場合は plugin の config 拡張 or upstream への PR で対処する (= 自前で WebAuthn 検証を上書きすることは禁止)
- **`passkey` テーブル schema は Better Auth が管理**: Atlas migration / Kysely 型生成は Better Auth が生成する schema を入力とする。手動で `passkey` table を ALTER することは禁止 (auto-migration と乖離する)
- **rp_id / origin / rpName の変更は Better Auth config 経由のみ**: Passkey 信頼境界に関わる設定は Env Service → plugin config 経路で一元管理する。コード上で別経路から rp_id を上書きすることは禁止

### Trade-offs と緩和策

- **Pros**: 実装量最小 / セキュリティリスクは Better Auth に集中 (= upstream に追従するだけで仕様改訂に対応) / Effect Layer への組み込みが宣言的 / passkey table schema の自動管理
- **Cons**: Better Auth 依存度が高まり、Better Auth から切り離す際の migration コストが発生 / WebAuthn の細かい振る舞いを直接コントロールできない
- **緩和策**: `identity-provider` の Service 抽象境界 (Effect Service 層) を維持し、Passkey 関連の操作は Service interface 経由で公開する。これにより将来 Better Auth から離脱する場合も、Service interface を保ったまま実装を差し替える経路が残る
