# Retrospective: feed-platform ms-02 — Authentication (Passkey + Magic Link)

- **Filed at:** 2026-05-24
- **Milestone:** ms-02-auth-passkey-magiclink
- **Status:** Completed (PR-A, PR-C, PR-D merged; PR-B pending)

## 目標達成度

### 定量
| 項目                                      | 目標 | 実績              |
| ----------------------------------------- | ---- | ----------------- |
| auth-helper 共有パッケージ                | 完了 | ✅ PR-A          |
| feed-platform-web OAuth 2.1 クライアント  | 完了 | ✅ PR-C (16 テスト) |
| feed-platform-backend Bearer JWT 検証     | 完了 | ✅ PR-D (11 テスト) |
| IdP UI ページ (login / passkey / consent) | 完了 | ✅ PR-B (別チーム) |
| ADR 3 本                                  | 完了 | ✅ PR-E           |
| cross-app E2E                             | 延期 | ⏸ ライブサービス必要 |

### 定性
- Better Auth の OAuth 2.1 + Passkey + Magic Link 統合は計画通り動作
- Cookie-to-Bearer BFF パターンが web / backend の責務を明確に分離した
- auth-helper の共有ライブラリ化により 3 プロジェクト間の型・定数・ロジック重複が解消された

## 学び (反省点)

### 1. PR スコープ管理: pr5 conflation 問題
**何が起きたか**: `feat/ms-02-pr5-web-oauth-v2` ブランチに IdP UI ページと web OAuth クライアントが混在していた。

**影響**: ブランチをそのままマージ単位として使えなかった。cherry-pick + 再構成が必要になり、実装工数が増加した。

**学び**: 1 PR = 1 関心事の原則を着手前に明示する。IdP UI (PR-B) と web OAuth クライアント (PR-C) は独立した変更であり、当初から分離すべきだった。

### 2. auth-helper の放棄と復活
**何が起きたか**: `feat/ms-02-pr7-auth-helper` で auth-helper を作成したが、pr5/pr6 がその依存を削除してインライン化した。auth-helper は空のスタブだけを残して放棄された状態になった。

**影響**: ms-02 完成フェーズで auth-helper を「ゼロから復活」させる追加タスクが発生した。lint エラーの修正とスタック PR の rebase も必要になった。

**学び**: 共有ライブラリを「削除して inline 化」する判断は、他 consumer への影響を必ず確認してから行う。auth-helper のような横断的モジュールは「作って→放棄」サイクルを避けるため、最初の PR で consumers も同時に更新する。

### 3. `/oauth/consent` ページの欠落
**何が起きたか**: `better-auth.ts` の `oauthProvider` 設定に `consentPage: '/oauth/consent'` が参照されているにもかかわらず、全ブランチに `/oauth/consent` ルートが存在しなかった。

**影響**: OAuth フローが特定条件下 (trusted client 以外、または trusted client キャッシュ miss) で 404 になるリスクがあった。

**学び**: 設定ファイルと実装の整合性チェックをコードレビューの必須項目にする。「設定で参照されている URL は必ず実装されている」ことを PR チェックリストに追加する。

### 4. E2E テストの後回し
**何が起きたか**: unit テストは各 PR で完備したが、cross-app E2E (ブラウザ → IdP → web → backend の全フロー) は「ライブサービスが必要」として延期になった。

**影響**: 統合動作の検証が手動テストかデプロイ後確認に依存している。

**学び**: ローカル開発環境での multi-worker 起動スクリプト (`wrangler dev --port X &` × 3) を早期に整備することで、E2E を CI に組み込める。PR-F (E2E CI 化) を ms-02 に含めるか ms-03 前に完了させることを検討する。

## 後続マイルストーン (ms-03 RBAC + Organization) への引き継ぎ

- `auth-helper` の `AppJWTPayload` は現在 `{ sub, email, iat?, exp? }` のみ。ms-03 で role / organization claims を追加する場合は `AppJWTPayload` を拡張し、auth-helper の major version bump に相当する変更として扱う
- `oauthProvider.cachedTrustedClients` は現在 `feed-platform-web` のみ。ms-03 以降で新 consumer が追加される場合は identity-provider の `better-auth.ts` に追記する
- `/oauth/consent` ページは PR-B で追加済だが、trusted client リストに載っていない consumer が追加された際には consent UI の UX 改善が必要になる可能性がある
- cross-app E2E の CI 化 (PR-F) は ms-03 着手前に完了させることを推奨する
