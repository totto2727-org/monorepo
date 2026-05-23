---
confirmed: true
scope: general
---

# ADR: Magic Link トークン形式 + Cloudflare Email Send 連携

- **Filed at:** 2026-05-21
- **Filer:** implementer (Step 6)
- **Originating step:** dev-workflow Step 6 (Implementation) of cycle `feed-platform-ms-02-passkey-magic-link`
- **Storage path:** docs/adr/2026-05-21-magic-link-token-and-email-delivery.md

## Status

`Accepted` — ms-02 (`feed-platform-ms-02-passkey-magic-link`) で確定。Magic Link 認証フローは `identity-provider` 内に閉じるが、`identity-provider` 自体が **汎用認証基幹サーバ** (ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` D-4) であるため、本リポジトリで認証認可を要する将来の他システムにも影響する。このため General mode (`docs/adr/`) に配置し、`scope: general` で保存する。

## Context

ms-02 で `identity-provider` に Magic Link 認証を実装する必要が生じた。Magic Link 認証フローは「ユーザがメールアドレスを入力 → サーバが one-time-use トークンを発行しメール送信 → ユーザがメール内リンクをクリック → サーバがトークンを検証してセッション確立」という構造をとる。

このフローの設計には以下 2 つの独立した決定が必要であった:

1. **トークン形式**: 発行するトークンを **opaque random token (DB-backed)** とするか **JWT (self-contained)** とするか
2. **メール配信経路**: メール送信を **Cloudflare Email Send REST API** で行うか **SMTP / nodemailer 等の外部 SMTP リレー** で行うか / テスト環境ではどう代替するか

本リポジトリの実行環境は Cloudflare Workers (= サーバレス) であり、長期接続を必要とする SMTP 直接送信は実行モデルと相性が悪い。また Better Auth は既に採用済 (ADR `2026-05-05-...` D-1 を実現する具体技術として ms-02 で導入) で、Magic Link 用の `magicLink` plugin が標準提供されている。

これらの前提のもと、トークン形式と配信経路を 1 つの決定束として確定する。

## Decision

本 ADR は 3 つの決定事項 (D-1〜D-3) を 1 つの決定束として確定する。

### D-1: Magic Link トークンは opaque random token (DB-backed)、NOT JWT

Magic Link 用トークンは Better Auth 既定の **opaque random token** (= `verification` テーブルで DB に永続化される one-time-use トークン) を採用する。JWT 形式は採用しない。

- **根拠 (revoke 容易性)**: one-time-use の本質は「使用済 / 期限切れトークンを即座に無効化する」こと。opaque random token は DB レコード削除 / `used_at` flag 設定で即時失効でき、トークン自体に状態を持たせる必要がない
- **根拠 (JWT 複雑性不要)**: JWT は self-contained で署名検証のみで完結する設計だが、one-time-use 要件下では JWT の利点 (= DB lookup 不要) が「使用済確認のための DB lookup が結局必要」になることで打ち消される。JWT の署名鍵管理 / claim 設計 / 期限フォーマット標準化コストに対して、得られる利点が薄い
- **根拠 (Better Auth 既定との整合)**: Better Auth の `magicLink` plugin は標準で verification テーブル経由の opaque token を採用しており、既定挙動を上書きする理由がない

### D-2: TTL は Better Auth 既定値を採用 (ms-10 で運用負荷を見て調整)

トークン TTL (有効期限) は **Better Auth `magicLink` plugin の既定値** をそのまま採用する。本 ms-02 では TTL を独自定数で上書きしない。

- **根拠**: ms-02 段階では本番運用データがなく、適切な TTL は経験的に定まる。Better Auth 既定値は OWASP 等の一般的なガイドラインに沿った値であり、初期値として妥当
- **将来調整パス**: ms-10 (= 運用フェーズ) で実際のメール到達遅延 / ユーザ操作時間分布 / 誤動作 (リンク先未訪問のままトークン期限切れ) の頻度を観測した上で、必要に応じて Better Auth config 経由で `expiresIn` を調整する

### D-3: メール配信は Cloudflare Email Send REST API、テスト環境は MockEmailSender Effect Service

メール配信経路は以下のように構成する。

- **Production**: Cloudflare Email Send REST API を Workers の `fetch` で呼び出す。SMTP / nodemailer 等の外部リレーは採用しない
- **Mock (CI / dev)**: `MockEmailSender` Effect Service を実装し、production と **同一 interface** (`EmailSender` Service) を提供する。Mock は実メール送信せず in-memory に送信履歴を保持する (or no-op)

- **根拠 (Cloudflare Email Send 採用)**:
  - 実行環境が Cloudflare Workers であり、SMTP の長期接続モデルとは相性が悪い (Workers の I/O モデルは `fetch` ベース)
  - Cloudflare Email Send は REST API で完結し、追加の外部 SMTP プロバイダ契約 / SMTP 認証情報管理が不要
  - Workers の `fetch` で呼び出すだけで完結し、追加の重い依存 (nodemailer 等の Node.js 専用パッケージ) を導入しない
- **根拠 (MockEmailSender 採用)**:
  - CI 環境で実メール送信が発生することを完全に防止する (= テストの副作用ゼロ化)
  - production と同一 `EmailSender` Service interface を提供することで、Better Auth `magicLink` plugin の `sendMagicLink` ハンドラは Layer の差し替えのみで CI / dev / production を切り替えられる
  - Effect Service として実装することで、`identity-provider` の他の Service 層 (DB / Env / Better Auth) と同一の Layer 合成パターンで扱える

### Alternatives considered

| Option          | Summary                                                                                                | Adopted / Rejected | Rationale                                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | opaque random token (DB-backed) + Cloudflare Email Send REST API + MockEmailSender Effect Service     | Adopted            | revoke 即時 / Workers 実行モデルに整合 / Better Auth 既定との整合 / CI で実メール送信ゼロ                                          |
| **B**           | JWT (self-contained) を Magic Link トークンに採用                                                      | Rejected           | one-time-use 要件下では DB lookup が結局必要で JWT の利点を打ち消す。署名鍵管理 / claim 設計の複雑性に対する利点が薄い             |
| **C**           | SMTP / nodemailer 経由でメール送信                                                                     | Rejected           | Workers の実行モデル (短命 fetch I/O) と SMTP の長期接続モデルが相性悪く、外部 SMTP プロバイダ契約 / 認証情報管理コストも発生 |
| **D**           | CI で実メール送信を行う (専用の送信先メールアドレスを用意)                                             | Rejected           | テストに副作用が発生し、メールプロバイダのレート制限 / 送信品質劣化 / 課金が発生する                                                |

## Consequences

### Newly added

- **`EmailSender` Effect Service の interface 確定**: `identity-provider/app/feature/email/sender.ts` に `EmailSender` Service が定義され、`send({ to, subject, text })` が標準 method として公開される
- **`CloudflareEmailSender` Layer (production)**: Cloudflare Email Send REST API を呼び出す実装が production Layer として提供される
- **`MockEmailSender` Layer (CI / dev)**: 同一 interface を提供する Mock 実装が CI / dev Layer として提供される。送信は no-op or in-memory 履歴保持
- **Better Auth `magicLink` plugin への `sendMagicLink` ハンドラ統合**: `sendMagicLink: ({ email, url }) => effectRunPromise(emailSender.send({...}))` の形で Effect Service と Better Auth が橋渡しされる
- **`verification` テーブルが Magic Link トークン永続化に使用される**: Better Auth が管理する `verification` テーブルに opaque random token が保存され、使用済 / 期限切れトークンは Better Auth の cleanup 機構で消去される

### Existing impact

- **ADR `2026-05-05-...` D-1 (4 構成要素) との整合**: Magic Link トークン永続化は `identity-provider` (= 基幹サーバ) の DB に閉じ、リソースサーバ側 (`feed-platform-backend`) は Magic Link の存在を意識しない (JWT 検証のみ)
- **将来の他システムへの影響**: `identity-provider` を再利用する将来の他システムも、Magic Link 認証を必要とする場合は本 ADR の選定 (opaque random token + Cloudflare Email Send) を引き継ぐ
- **`identity-provider/wrangler.jsonc` の binding**: Cloudflare Email Send 利用に伴う `send_email` binding (or 該当する Workers binding) が wrangler 設定に追加される

### Constraints going forward

- **Magic Link トークンを JWT に変更する場合は本 ADR を Superseded**: opaque random token から JWT への変更は本 ADR の根幹 (D-1) を覆すため、別 ADR を起票し本 ADR を Superseded する形で扱う
- **SMTP / nodemailer 等の外部 SMTP リレーへの差し替え禁止**: Workers 実行モデルとの非整合のため、将来も Cloudflare Email Send REST API (or 同等の REST 型メール送信 API) を採用する
- **CI 環境で実メール送信を発生させることは禁止**: テストは必ず `MockEmailSender` Layer に依存させる。production Layer (CloudflareEmailSender) を CI で読み込むことは禁止
- **`EmailSender` Service interface の変更は破壊的変更扱い**: production / Mock の両 Layer が同一 interface に依存しているため、interface 変更は両 Layer を同時に追従させる

### Trade-offs と緩和策

- **Pros**: revoke 即時 (DB delete) / Workers 実行モデルに整合 / CI で実メール送信ゼロ / Better Auth 既定と整合し追加実装最小
- **Cons**: revoke 確認に DB round-trip が必要 (JWT の self-contained 検証より遅い) / メール配信が Cloudflare Workers の `fetch` 経路のみに限定される (= Workers 外の実行環境では別経路の Layer が必要)
- **緩和策**: DB round-trip コストは Magic Link 検証時 (= ログインフロー時のみ発生) であり、通常リクエスト経路 (JWT 検証経路) には影響しない。Workers 外の実行環境が必要になった場合は `EmailSender` Service interface を保ったまま別 Layer を追加する経路が残る
