---
confirmed: true
scope: general
---

# ADR: identity-provider と authn/authz アーキテクチャ

- **Filed at:** 2026-05-06
- **Filer:** implementer (Step 6)
- **Originating step:** dev-workflow Step 6 (Implementation) of cycle `feed-platform-ms-01-workspace-foundation`
- **Storage path:** docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md

## Status

`Accepted` — 本 ms-01 サイクル (`feed-platform-ms-01-workspace-foundation`) で確定。`identity-provider` プロジェクトの汎用化方針 (= 他システム再利用視野) と認証認可アーキテクチャ大枠は、feed-platform ロードマップ内の後続マイルストーン (ms-02 / ms-03 / ms-04 等) のみならず、**本リポジトリで認証認可を要する将来の他システム**にも影響する。このため General mode (`docs/adr/`) に配置する。

## Context

`feed-platform` ロードマップは認証認可要件として OAuth 2.1 / Passkey / Magic Link / RBAC / Organization 切替 / 期間限定共有を含み、ms-02〜ms-04 にわたって段階的に実装される予定である。これらの認証認可機能は **単独システム (= feed-platform 専用)** として実装することも可能だが、以下の動機で **汎用化** を選択した:

- 本リポジトリは monorepo であり、将来他システム (= feed-platform とは別の dev-workflow ロードマップで起こされるシステム) でも認証認可機能を必要とする可能性が高い
- 認証認可は機能要件として共通性が高く (OIDC / OAuth 2.1 が標準化されている)、再実装すると保守コスト / セキュリティリスクが二重に発生する
- ロードマップ Intent (`docs/roadmap/feed-platform/roadmap.md`) で確定した「サーバレスアーキテクチャ原則」を満たすには、**通常リクエスト処理経路に認可サーバ問い合わせを発生させない設計**が必要であり、この設計は feed-platform 固有要件でなく一般性の高い構造として整備する価値がある
- ポリシー (= ロール × 操作の許可マッピング) を **Git 管理可能なコードレベル契約**として配布する方式は、複数システムで再利用可能な共通基盤として位置付けるのが自然

intent-spec.md (`docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md`) の Q2.7 / Q2.7-extension / Q2.8 / Q2.11-extension で確定した 4 件の決定事項を、本 ADR が認証認可アーキテクチャの不変記録として永続化する。

具体技術選定 (Better Auth / jose / Casbin 等の採用判定 / Passkey + Magic Link 実装方式 / RBAC 実装の詳細) は **feed-platform ロードマップの ms-02 / ms-03 / ms-04 で確定**する。本 ADR は **アーキテクチャ大枠** (= 構成要素の責務分担 + JWT 送信方法 + プロジェクト命名 + 拡張パスのインターフェース不変原則) に範囲を限定する。技術選定の素案は `docs/roadmap/feed-platform/design-hint.md` の「認証認可アーキテクチャの素案」節 (A〜J 全節) に保留される。

影響範囲は **feed-platform ロードマップ全体 + 本リポジトリで認証認可を要する将来の他システム**。このため General mode (`docs/adr/`) として起票し、`scope: general` で保存。プロジェクト構造と実行環境 (= feed-platform 内に閉じる構造的決定) は別 ADR (ADR-01 Roadmap mode) に分離した。

## Decision

本 ADR は 6 つの決定事項 (D-1〜D-6) を 1 つの決定束として確定する。各決定はそれ単体で機能するが、合わせて「サーバレス相性最大化 + ポリシーの Git 管理 + 汎用 IdP + authn/authz の命名分離 + 将来の独立 PDP 移行可能性」というアーキテクチャ大枠を構成する。

### D-1: 認証認可の 4 構成要素

認証認可システムを以下の 4 構成要素に分解し、責務 / DB 所有 / 認可ロジック保持を明示する (intent-spec Q2.7、design-hint §A 参照)。

| 構成要素                                                                | 役割                                                                                                                     | DB 所有                                   | 認証認可ロジック                    |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------- | ----------------------------------- |
| **クライアント** (Web フロント / 将来 mobile / CLI)                     | OAuth 2.1 クライアントとして JWT を取得 / 送信                                                                           | ×                                         | なし (トークン保持のみ)             |
| **基幹サーバ** (`identity-provider`)                                    | 認証 (パスワード / Passkey / Magic Link 等) + 組織 / メンバー / ロール管理 + OAuth 2.1 認可フロー + JWT 発行 + JWKS 公開 | **○** (users / sessions / orgs / members) | あり (ロール割当の唯一の真実 = SoT) |
| **リソースサーバ** (バックエンド側 BFF / API = `feed-platform-backend`) | JWT 検証 (JWKS キャッシュ) + 認可判定 (in-memory) + ビジネスロジック                                                     | × (基幹 DB は共有しない / 業務 DB は別個) | あり (リクエスト時判定)             |
| **共有 authz パッケージ**                                               | ロール定義 + ポリシー (`policy.csv` 相当) + `can(jwt, resource, action)` 関数                                            | —                                         | ポリシー定義のソース                |

認証認可フローの構造的特性:

- クライアント → (OAuth 2.1 + PKCE) → 基幹サーバ → JWT 発行 → クライアント → (Bearer JWT) → リソースサーバ → ローカル JWT 検証 + ローカル認可判定 → ビジネスロジック実行
- **通常リクエスト経路に基幹サーバ問い合わせは発生しない** (基幹サーバへのアクセスはログイン時 / トークン更新時のみ)
- リソースサーバは JWKS をキャッシュし、JWT 検証 / 認可判定は in-memory で完結する (= サーバレス相性最大化)
- ポリシーは共有 authz パッケージとして Git 管理されるコードレベル契約 (= ランタイム動的ロード不採用)

### D-2: JWT 送信方法 (Cookie / Authorization Bearer の使い分け)

JWT の送信方法はクライアント種別と通信先によって以下のように使い分ける (intent-spec Q2.7-extension、design-hint §H 参照)。

| 通信経路                                                 | 送信方法                         | 備考                                                                                              |
| -------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------- |
| ブラウザ ↔ Web フロントエンドサーバ (SSR + 軽量 BFF)     | **Cookie**                       | リンク遷移 / form submission で自然に認証情報伝搬 (= 通常の Web ナビゲーションが認証下で機能する) |
| Web フロントエンドサーバ → リソースサーバ (バックエンド) | **`Authorization: Bearer`**      | Cookie から JWT を抽出し Bearer ヘッダーに付け替え (BFF パターンの Cookie ↔ Bearer 翻訳責務)      |
| Mobile / CLI / ブラウザ JS から直接 → リソースサーバ     | **`Authorization: Bearer`**      | OAuth 2.1 標準の Bearer 送信                                                                      |
| クライアント ↔ 基幹サーバ (ログイン / トークン更新)      | OAuth 2.1 標準フロー (PKCE 使用) | 認可コードフロー / トークンエンドポイントは OAuth 2.1 仕様準拠                                    |

Cookie 属性の素案 (詳細は ms-02 で確定): `Secure` 本番必須 / `SameSite=Lax` 推奨 / `Path=/` / `Domain` 暗黙設定。

**Cookie の `httponly` 属性採用判断は ms-02 に委譲**: XSS 起因の JWT 漏洩抑止という水際対策効果と、クライアントサイド JS からの操作可否 (例: クライアント側でのトークン期限検知 / 手動クリア) のトレードオフを ms-02 (Passkey + Magic Link) の Step 3 (Design) で確定する。素案は `httponly` 採用 default (BFF パターンによる Cookie ↔ Bearer 翻訳が成立すればクライアント JS が JWT を直接扱う必要がないため自然) だが、これは本 ADR 確定範囲外。

### D-3: リソースサーバは Authorization ヘッダー由来の JWT のみで認証する (Cookie を一切受理しない)

**リソースサーバ (= バックエンド側 BFF / API) は Cookie を一切受理せず、`Authorization: Bearer` ヘッダー由来の JWT のみを認証情報として扱う** (intent-spec Q2.7-extension)。

- **根拠**: 信頼境界を Authorization ヘッダー由来の JWT に統一することで、リソースサーバの認証ロジックが単一経路に集約される。Cookie ↔ Bearer の翻訳責務は Web フロントエンドサーバ (= BFF パターン) に閉じ、リソースサーバはどのクライアント種別 (Web / Mobile / CLI) からのリクエストでも同一経路で扱える
- **副次効果**: CSRF 攻撃の主たる経路 (= Cookie 自動送信) がリソースサーバに到達しないため、リソースサーバ側で CSRF 対策コードを書く必要がなくなる

### D-4: `identity-provider` プロジェクトの汎用化方針

基幹サーバは **`feed-platform-*` 名前空間外の独立した 3 番目のプロジェクト**として配置し、**汎用認証基幹サーバ**として設計する (intent-spec Q2.8、ADR-01 D-2 / D-5 参照)。

- **プロジェクト命名**: `identity-provider` (= OIDC / OAuth 2.1 における Identity Provider)
- **配置**: `js/app/identity-provider/` (ADR-01 D-5 で確定)
- **汎用化の意味**:
  - feed-platform 専用機能を `identity-provider` 内のコアに含めない (組織管理 / RBAC は OIDC / OAuth 2.1 標準の範囲で汎用的に設計)
  - 他システム (= 本リポジトリで認証認可を要する将来の dev-workflow ロードマップ配下システム) が `identity-provider` を **そのまま再利用可能** な状態を維持する
  - feed-platform 固有のロール定義 (例: 「フィードオーナー」「フィードメンバー」等) は **共有 authz パッケージ側 (or feed-platform 専用 authz パッケージ側)** で表現し、`identity-provider` 内には埋め込まない (この境界は ms-03 で確定)
- **実装作業の委譲**: feed-platform ロードマップ ms-02 (Passkey + Magic Link) / ms-03 (RBAC + Organization) / ms-04 (期間限定共有) が `identity-provider` の機能を実装するが、**feed-platform 固有要件に閉じない汎用性を維持した設計**とする (ms-02 以降のサイクルが本 ADR を遵守責任を負う)

### D-5: authn (認証) と authz (認可) のコード命名上の区別原則

認証 (authentication, authn) と認可 (authorization, authz) を **コード命名レベルで区別** する (intent-spec Q2.11-extension)。

- **認証 (authn) 担当** = `identity-provider` (ID / クレデンシャル検証 + JWT 発行 + 組織 / メンバー / ロールの SoT 保持)
- **認可 (authz) 担当** = リソースサーバ内の認可判定 + 共有 authz パッケージ (将来の独立 PDP に分離可能)
- **将来の `authz-server` 想定**: D-6 の Phase 4 (独立 PDP 移行) 発生時、`identity-provider` (authn) と並置する形で `authz-server` (authz) を新設する。命名は `identity-provider` ↔ `authz-server` の対比を保つことで認証認可分離後も整合する

具体例 (TypeScript identifier レベル):

```typescript
// 認証 (authn) — identity-provider 内の責務
interface IdentityProvider {
  authenticate(credential: Credential): Promise<JWT>
  refresh(refreshToken: string): Promise<JWT>
  revoke(refreshToken: string): Promise<void>
}

// 認可 (authz) — 共有 authz パッケージ + リソースサーバ内
function can(jwt: AppJWTPayload, resource: Resource, action: Action): Promise<boolean>
```

`identity-provider` 内に `can()` を実装したり、リソースサーバ内に JWT 発行ロジックを置いたりすることは **本 ADR の命名規約違反**として扱う。

### D-6: `can()` インターフェース不変原則による拡張パス

認可判定インターフェース `can(jwt, resource, action) -> boolean` を **不変に保ったまま、内部実装を段階的に進化させる構造**を採用する (intent-spec Q2.7、design-hint §I 参照)。

| Phase                  | 移行のトリガー              | 内部実装変更                                                                         |
| ---------------------- | --------------------------- | ------------------------------------------------------------------------------------ |
| **Phase 1 (現行素案)** | —                           | Casbin in-memory + 静的ポリシー (素案、ms-03 で確定)                                 |
| Phase 2                | permission 単位の判定が必要 | JWT に permissions 配列を展開、policy も permission ベースに変更                     |
| Phase 3                | テナント独自ロールが必要    | 基幹サーバで動的アクセス制御を有効化                                                 |
| Phase 4                | 動的ポリシー管理が必要      | 認可サービスを分離し `can()` を HTTP 呼び出しに差し替え (= 独立 `authz-server` 起動) |
| Phase 5                | 言語混在や大規模化          | OPA 等の独立 PDP に移行                                                              |

各 Phase でリソースサーバ側のコードはほぼ変更不要 (= 共有 authz パッケージの内部実装のみが進化)。これにより認可方式の進化はビジネスロジックの変更を引き起こさない。

### Alternatives considered

| Option          | Summary                                                                                                                                               | Adopted / Rejected | Rationale                                                                                                        |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | 4 構成要素 (クライアント / 基幹サーバ / リソースサーバ / 共有 authz パッケージ) + JWT (Cookie ↔ Bearer 翻訳) + 汎用 IdP + 命名分離 + `can()` 不変原則 | Adopted            | サーバレス相性最大化 + ポリシー Git 管理 + 認証認可分離の将来性をすべて担保                                      |
| **B**           | リソースサーバが基幹サーバ DB を直接共有 (single DB)                                                                                                  | Rejected           | 認可境界の曖昧化 / 障害伝播 / スキーマ結合のリスク。サーバレス + マイクロサービス境界原則と矛盾                  |
| **C**           | リソースサーバが認可判定を毎回基幹サーバに HTTP で問い合わせる                                                                                        | Rejected           | 通常リクエスト経路にレイテンシ + 認可サーバ障害伝播。サーバレス相性最悪                                          |
| **D**           | `identity-provider` を `feed-platform-identity-provider` 命名で feed-platform 専用に閉じる                                                            | Rejected           | 他システム再利用が不可能になり、本リポジトリ全体の認証認可を二重実装するコストが将来発生                         |
| **E**           | リソースサーバが Cookie + Bearer の両方を受理する                                                                                                     | Rejected           | 認証経路が二重化し、CSRF 対策コードがリソースサーバ側にも必要、信頼境界が曖昧化                                  |
| **F**           | authn と authz を命名分離せず `auth-server` 等で統合                                                                                                  | Rejected           | Phase 4 (独立 PDP 移行) 発生時にプロジェクト分離が困難、将来の `authz-server` 独立時に命名衝突の整理コストが発生 |

## Consequences

### Newly added

- **`identity-provider` プロジェクト** (`js/app/identity-provider/`、ADR-01 D-2 で配置確定): ms-01 では Hello World レベルの雛形のみだが、**汎用認証基幹サーバとしての位置付け** が本 ADR で確定。OAuth 2.1 / Better Auth / 認証フレームワーク導入は ms-02 委譲
- **DB binding コメント予約 in `identity-provider/wrangler.jsonc`**: ms-02 で BetterAuth (or 代替) を採用する際の引き継ぎ点として `d1_databases` / `kv_namespaces` / `BETTER_AUTH_*` vars の 3 種コメントを予約済 (本 ms-01 の T-J commit `80f3ca8`)
- **JWT 送信方法の信頼境界**: リソースサーバ (= `feed-platform-backend`) は Authorization ヘッダー由来の JWT のみで認証する原則が確定。Web フロントエンドサーバ (`feed-platform-web`) が Cookie ↔ Bearer 翻訳責務を負う (実装は ms-07 委譲)
- **共有 authz パッケージ位置付け**: コードレベル契約 (`can(jwt, resource, action)` 関数 + ロール定義 + ポリシー) として Git 管理配布される。配置先 (`js/package/authz/` 汎用 vs `js/package/feed-platform-authz/` feed-platform 専用) は ms-03 で確定 (本 ADR では確定しない)
- **将来の `authz-server` 独立プロジェクト想定**: Phase 4 (独立 PDP 移行) 発生時に `identity-provider` (authn) ↔ `authz-server` (authz) の命名対比を保つ前提が確定

### Existing impact

- **本リポジトリの将来的な他システム** (= `feed-platform` とは別の dev-workflow ロードマップで起こされるシステム) が認証認可を要する場合、それらは **`identity-provider` を再利用するか / 別の認証基幹サーバを起こすか** の判断を、本 ADR を参照した上で行う必要がある。再利用が推奨パスとなり、別システム独自の `<system>-identity-provider` を起こすことは原則として避ける
- **既存実装への影響なし**: 本 ms-01 段階では `identity-provider` は Hello World 雛形のみ、`feed-platform-backend` は `/health` 200 OK + `/bff` 雛形のみで実体の認証認可ロジックは存在しない。本 ADR は **将来の実装に対する不変原則の宣言**として機能する
- **`feed-platform-backend` の各 entry の認証ミドルウェア**: ms-02 以降で追加される認証ミドルウェアは、本 ADR D-3 (Cookie 受理禁止 / Bearer のみ) を遵守する形で実装される
- **`feed-platform-web` の middleware 順序**: 本 ms-01 では `logger → contextStorage → runtimeMiddleware → remixRenderer` (T-G commit `ee21531`) で確定済だが、ms-02 以降で BFF パターンの Cookie ↔ Bearer 翻訳ミドルウェア (= D-2 要件) が追加される際、上記 middleware 連の中間に挿入される (実装は ms-07 委譲)

### Constraints going forward

後続マイルストーン (feed-platform 内 + 将来の他システム) は以下の不変制約を遵守する:

- **4 構成要素の責務分担は不変**: 基幹サーバが業務 DB を所有することや、リソースサーバが認証認可 DB を所有することは禁止。共有 DB 採用も禁止 (D-1)
- **JWT 送信方法は通信経路ごとに定められた方法を遵守**: Web フロントサーバを介さない直接呼び出しは Bearer のみ。リソースサーバが Cookie を受理することは禁止 (D-2 / D-3)
- **`identity-provider` の汎用性を毀損しない**: feed-platform 固有の機能 (フィード固有のロール定義 / 期間限定共有のロジック等) を `identity-provider` 内に埋め込むことは禁止。それらは共有 authz パッケージ側 (or feed-platform 専用 authz パッケージ側) で表現する (D-4)
- **authn / authz の命名分離原則**: `identity-provider` 内に認可判定 (`can()`) を実装することや、リソースサーバ内に JWT 発行ロジックを置くことは禁止 (D-5)
- **`can()` インターフェースは不変**: Phase 1〜5 のいずれの段階でも `can(jwt, resource, action) -> boolean` のシグネチャを維持する。シグネチャ変更が必要な場合は本 ADR を Superseded する形で別 ADR を起票する (D-6)
- **通常リクエスト経路に基幹サーバ問い合わせを発生させない**: リソースサーバは JWKS をキャッシュし、JWT 検証 / 認可判定を in-memory で完結させる (D-1)

### Trade-offs と緩和策

- **Pros**: 通常リクエスト経路が認可サーバ問い合わせ不要 (= サーバレス相性最大化) / ポリシーが Git 管理可能 (コードレベル契約) / 将来の独立 PDP 移行が `can()` 内部実装変更のみで済む / `identity-provider` の他システム再利用が成立 / authn/authz 分離により Phase 4 移行時のプロジェクト整理がスムーズ
- **Cons**: Phase 4 (動的ポリシー) 移行時に `can()` 実装が HTTP 呼出になる際のレイテンシ管理が必要 / Cookie ↔ Bearer 翻訳責務が Web フロントエンドサーバの肥大化要因 / リソースサーバから見ると Cookie 由来のリクエストが弾かれるため、フロントエンド以外からの直接的な Web ブラウザ呼び出し (= form submission 等) を要する場合は別経路を要する
- **Mitigation**: Phase 移行は ms-03 以降で慎重に判断 (移行前に `can()` 利用箇所のレイテンシ予算を確保) / 翻訳責務は Web フロントエンドサーバの dedicated middleware として隔離 (ms-07 で実装、`logger → contextStorage → runtimeMiddleware → cookieToBearer → remixRenderer` の連の中に挿入予定) / リソースサーバへの直接 form submission ニーズは Web フロントエンドサーバ経由で吸収する設計を維持

## References

- **Intent Spec**: `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md` (Q2.7 / Q2.7-extension / Q2.8 / Q2.11-extension)
- **Design Document**: `docs/workflow/feed-platform-ms-01-workspace-foundation/design.md` (S-4 認証認可 4 構成要素の物理配置 / ADR-02 outline L1113-1142)
- **Design Hint**: `docs/roadmap/feed-platform/design-hint.md` §「認証認可アーキテクチャの素案」(A〜J 全節、特に A-0 用語と命名 / A 構成要素 / B 全体構成図 / C 認証認可シーケンス / D 具体技術選定素案 / E JWT ペイロード設計素案 / F 認可判定実装イメージ / G DB 所有方針 / H JWT 送信方法と Cookie 設定 / I 拡張パス / J 委譲先)
- **Related Roadmap**: `docs/roadmap/feed-platform/roadmap.md` (アーキテクチャ的制約 / ms-02 / ms-03 / ms-04 マイルストーン定義)
- **Related Milestones**: `docs/roadmap/feed-platform/milestones/ms-02-passkey-magic-link.md` / `ms-03-rbac-organization.md` / `ms-04-time-limited-sharing.md` (`identity-provider` の機能を段階的に実装)
- **Related ADR**: `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md` (ADR-01、本 ADR と対をなす Roadmap mode ADR。プロジェクト構造 / 実行環境 / `identity-provider` の物理配置を確定)
- **Implementation commits (ms-01 雛形)**: T-I `da5dfaf` (`identity-provider` プロジェクト全体) / T-J `80f3ca8` (DB binding コメント予約)
