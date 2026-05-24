---
confirmed: true
scope: roadmap:feed-platform
---

# ADR: feed-platform Magic Link 認証戦略

- **Filed at:** 2026-05-24
- **Filer:** implementer (ms-02 Wave 2)
- **Originating step:** ms-02 (Authentication — Passkey + Magic Link) implementation
- **Storage path:** docs/adr/2026-05-24-feed-platform-magic-link-strategy.md

## Status

`Accepted` — ms-02 で確定。identity-provider の Magic Link 認証実装方針として採用。

## Context

`docs/roadmap/feed-platform/roadmap.md` の ms-02 要件として Passkey に加えて Magic Link による認証が定義されている。Magic Link はパスワードレス認証の fallback / 初回登録経路として機能する。以下の設計決定が必要だった。

- トークン有効期限: 短すぎるとユーザ体験が悪化、長すぎるとセキュリティリスクが増大する
- 配信経路: メール送信インフラの選択
- 再利用防止: 同一リンクの複数回使用を防ぐ
- Passkey との共存: WebAuthn Passkey 登録済ユーザへの Magic Link 提供方針

## Decision

### D-1: トークン有効期限 — Better Auth デフォルト (10 分) を採用

| Option | 有効期限 | 採否     | 理由                                                                                          |
| ------ | -------- | -------- | --------------------------------------------------------------------------------------------- |
| 10 分  | 10 min   | **採用** | Better Auth デフォルト。業界標準 (GitHub / Slack 等と同等)、攻撃ウィンドウが限定的            |
| 30 分  | 30 min   | 却下     | ユーザ体験は改善するが攻撃ウィンドウが 3 倍になる。passkey 登録後は magic link 頻度低下見込み |
| 5 分   | 5 min    | 却下     | メール遅延が発生した場合にリンク失効が多発しサポートコスト増大                                |

Better Auth の `magicLink` プラグインの `expiresIn` をデフォルト値から変更しない。

### D-2: トークン単一使用 (Single-Use)

Magic Link トークンは **1 回の使用で即座に無効化**する。これは Better Auth `magicLink` プラグインの組み込み動作であり、追加実装は不要。

### D-3: 配信経路 — Cloudflare Email Workers (本番) / Mock (開発)

| Option                   | 概要                                         | 採否     | 理由                                                             |
| ------------------------ | -------------------------------------------- | -------- | ---------------------------------------------------------------- |
| Cloudflare Email Workers | Cloudflare の Email Routing + Workers で送信 | **採用** | monorepo のインフラ統一 (Cloudflare Workers)、追加 SaaS 契約不要 |
| SendGrid / AWS SES       | 外部メール配信 SaaS                          | 却下     | 外部 SaaS 依存追加、コスト発生、monorepo インフラから逸脱        |
| SMTP 直接送信            | SMTP サーバへ直接送信                        | 却下     | Cloudflare Workers から TCP 直接送信は制限あり                   |

実装: `app/feature/email/sender.ts` → 本番: `cloudflare.ts` / 開発: `mock.ts` (コンソール出力)

### D-4: Passkey との共存

Passkey と Magic Link は **排他ではなく並列提供**する。

- 初回認証 / Passkey 未登録: Magic Link を主経路とする
- Passkey 登録済ユーザ: Passkey を推奨、Magic Link はアカウントリカバリ / 新デバイス初期設定として維持

ユーザが両方を持つ場合、IdP のログイン画面 (`/login`) で両方の選択肢を提示する。

## Consequences

- **Newly added:** `js/app/identity-provider/app/feature/email/` に sender.ts / cloudflare.ts / mock.ts が実装された。Better Auth config (`better-auth.ts`) に `magicLink` プラグインと `sendMagicLink` コールバックが設定された
- **Existing impact:** ユーザが Magic Link を要求するたびにメール送信が発生する。Cloudflare Email Workers の送信クォータに注意すること
- **Constraints going forward:**
  - Magic Link 有効期限 (10 分) は Better Auth プラグイン設定で管理。変更する場合は `better-auth.ts` の `magicLink.expiresIn` を明示的に設定する
  - 本番メール送信は Cloudflare Email Workers の設定 (DNS, routing) が必要。`wrangler.jsonc` の `send_email` binding を確認すること
  - Magic Link トークンの再利用防止は Better Auth に委ねる。手動での DB クリーンアップは不要

## Related

- [feed-platform 認証プロバイダとして Better Auth を採用](./2026-05-24-feed-platform-auth-provider.md)
- [feed-platform cross-app セッション戦略](./2026-05-24-feed-platform-cross-app-session-strategy.md)
- [identity-provider と authn/authz アーキテクチャ](./2026-05-05-identity-provider-and-authn-authz-architecture.md)
