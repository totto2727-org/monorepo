# Review Report: Security

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** security — Independent verification of secret handling, attack surface minimisation, trust boundary preparation, and supply-chain hygiene at ms-01 scope only
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate (this Round only):** approved
- **Round count:** 1

## Summary

ms-01 雛形整備サイクルの security 観点レビュー完了。**Blocker 0 / Major 0 / Minor 2 / Info 7**。攻撃面は最小 (`/health` GET only / DB binding 未配線 / 認証コード不在) で、intent-spec.md L178「機密情報をリポジトリに保存しない」/ TC-023 / ADR-02 D-3 の 3 大規範的制約はすべて満たされている。ms-01 スコープを越える security 懸念は検出されず。

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                           | Status              | Detected Round |
| --- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | -------------- |
| m-1 | Minor    | `js/app/identity-provider/.gitignore:1-2` に `worker-configuration.d.ts` が未登録。`feed-platform-backend/.gitignore:3-4` と `feed-platform-web/.gitignore:3` には登録済。ms-02 で `wrangler types` 実行時に 492KB の d.ts が gitignored されず混入する将来リスク | pending             | 1              |
| m-2 | Minor    | `js/app/identity-provider/wrangler.jsonc:22-25` で `BETTER_AUTH_SECRET` reservation が live `vars` block 内に置かれている。`d1_databases` / `kv_namespaces` は file top level (line 27-34)。3 reservation の co-location が design.md L808-811 と異なる           | accepted-as-is      | 1              |
| i-1 | Info     | `effect: beta` (catalog `pnpm-workspace.yaml:36`) と `remix: ^3.0.0-beta.0` (line 50) は pre-release。ms-01 では問題なし、Step 9 retrospective で監視候補                                                                                                         | (consistency check) | 1              |
| i-2 | Info     | `compatibility_flags: ["nodejs_compat"]` は ADR-01 D-6 line 86 で「`crypto.randomUUID` 等が要求するため」と記載されているが、`crypto.randomUUID` は Workers core の Web Crypto API で利用可能。Effect / Hono の他依存が真の理由                                   | (consistency check) | 1              |
| i-3 | Info     | `vars: { ENV: "development" }` のみで本番値・secrets はリポジトリ未存在。`wrangler secret put` 経由で deploy 時注入が前提 (intent-spec.md L178 整合)                                                                                                              | (consistency check) | 1              |
| i-4 | Info     | `await using runtime = Runtime.make(c.env)` (`feature/runtime/hono.ts:17` 全 3 プロジェクト) が request-scoped 解放を確実化。ms-02+ の認証 state にも自動適用                                                                                                     | (consistency check) | 1              |
| i-5 | Info     | Service tag namespace `@app/<project-name>/feature/<name>/Service` が 9 service tags すべてで unique (env / greeting / health × 3 projects)、衝突可能性なし                                                                                                       | (consistency check) | 1              |
| i-6 | Info     | `feed-platform-backend/src/{health,bff}/worker.ts:20+` の `/health` は GET only / static JSON / no body parsing。攻撃面 = idempotent GET のみで最小                                                                                                               | (consistency check) | 1              |
| i-7 | Info     | ADR-02 D-3 (`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md:69-74`) で「リソースサーバは Cookie 受理せず Bearer のみ」を ms-02+ への不変制約として確立。CSRF/XSS/token leak attack model を architecture 層で先回り遮断                    | (consistency check) | 1              |
| i-8 | Info     | `.env*` / `.pem` / `.key` / `secrets.*` / hardcoded credentials は全 3 プロジェクト不在 (grep `SECRET\|API_KEY\|API_TOKEN\|PASSWORD\|PRIVATE_KEY\|sk_live\|sk_test\|ghp_\|github_pat\|aws_access_key` で確認)                                                     | (consistency check) | 1              |
| i-9 | Info     | CORS / CSRF / Cookie middleware は全 3 プロジェクト不在 (auto-generated `worker-configuration.d.ts` の Cloudflare 型のみが grep hit)。ms-01 段階では正解 (defend する auth surface 不在)                                                                          | (consistency check) | 1              |

## Detail sections

### m-1 detail: `worker-configuration.d.ts` should be gitignored in identity-provider proactively

`js/app/identity-provider/.gitignore` が `dist/` + `.wrangler/` のみで `worker-configuration.d.ts` 不在。

`feed-platform-web/.gitignore` には `worker-configuration.d.ts` が登録、`feed-platform-backend/.gitignore` には per-entry (`src/bff/worker-configuration.d.ts` + `src/health/worker-configuration.d.ts`) で登録されている。

IdP の `vite.config.ts:5-15` には `setup:cloudflare` task が未定義のため、現状 d.ts は生成されない。**しかし ms-02 implementer が D1 / KV bindings を追加して `wrangler types` を実行すると 492KB の d.ts が IdP source tree に materialise される**。Cloudflare 生成の d.ts は binding 名と resource shape を embed するため、ms-02 で account-internal 情報が誤 commit される将来リスク。

**Severity Minor 根拠**: (a) ファイル現存せず、(b) Cloudflare 生成 d.ts は secret 分類でない、(c) design.md L851 は登録を推奨 (mandatory ではない)。ms-01 段階で `.gitignore` 1 行追加で予防可能。

### i-2 detail: `nodejs_compat` rationale precision in ADR-01

ADR-01 D-6 (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md:86`) の根拠で挙げられた `crypto.randomUUID` は Workers' default runtime で利用可能 (Web Crypto API)、`nodejs_compat` 不要。実態は **Effect** (Node `Buffer` / `process` runtime probes) と **Hono** (Node-only adapter paths) が真の理由。`crypto.randomUUID` 例示は誤誘導。security 観点では `nodejs_compat` で sandbox API surface (`process` / `Buffer` / `async_hooks` / `crypto` Node 形 / `events` / `path`) が拡大するが、ms-01 Hello World には不要。実装そのものは問題なし、将来 ADR 改訂時の rationale 精緻化を推奨。

## Round history meta

| Round | Date       | Reviewer instance             | Single-Round Gate |
| ----- | ---------- | ----------------------------- | ----------------- |
| 1     | 2026-05-06 | reviewer (security, parallel) | approved          |

Final Gate: `approved`. 0 Blocker / 0 Major / 2 Minor (1 pending, 1 accepted-as-is) / 7 Info.

## Open questions for Step 8 / Step 9

- m-1 の修正を ms-01 内で実施するか / ms-02 の T-I 拡張で扱うか は user judgment。design.md L851 への準拠重視なら ms-01 内修正。
- i-1 の pre-release dependency (effect beta / remix beta) 監視は Step 9 retrospective 候補。
- i-2 の ADR-01 D-6 rationale 修正は将来 ADR amendment 候補 (本サイクル外)。
