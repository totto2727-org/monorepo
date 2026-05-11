# Retrospective: 2026-05-11-bw-effect-undici-content-length

- **Identifier:** 2026-05-11-bw-effect-undici-content-length
- **Created at:** 2026-05-11

## Context

`bw` CLI (Cloudflare Browser Rendering wrapper) failed in published form (`bunx @totto2727/bw@<x>`) with `Transport error ... InvalidArgumentError: invalid content-length header` while local builds succeeded. Released `0.1.3` to expose the cause chain, `0.1.4` to bump `effect` to `4.0.0-beta.65`, and `0.1.5` with the actual fix.

## Root cause

1. `import { NodeRuntime, NodeServices } from '@effect/platform-node'` pulls the package root `index.js`.
2. `index.js` re-exports `Undici.js`, which is `import Undici from "undici"; export * from "undici"; export default Undici`.
3. `import 'undici'` (npm undici `8.2.0`) registers itself as the global dispatcher in Node 24.15.0+, so `globalThis.fetch` routes through npm undici instead of the vendored one.
4. Effect builds a `HttpBody.uint8Array` whose `contentLength` is `body.length`. `HttpClientRequest.setBody` then writes `Headers.set(headers, "content-length", body.contentLength.toString())` — a manual `Content-Length: "29"`.
5. Node 24 fetch + npm undici 8.2.0 also auto-derives Content-Length from the body bytes; the two values are joined as `"29, 29"` in `HeadersList`.
6. undici 8.2.0 `processHeader` (added by [PR #5060](https://github.com/nodejs/undici/pull/5060)) strict-rejects non-digit Content-Length values → `InvalidArgumentError: invalid content-length header`.

Node 24.14.0 + earlier undici (`8.1.0` / `8.0.3` / `7.25.0`) tolerated the duplicated value, so the bug only surfaces on Node 24.15.0 with undici 8.2.0+.

## Fix shipped

`bw` 0.1.5 switched to deep imports so `Undici.js` is never evaluated:

```ts
import * as NodeRuntime from '@effect/platform-node/NodeRuntime'
import * as NodeServices from '@effect/platform-node/NodeServices'
```

Without `import 'undici'` as a side-effect, `globalThis.fetch` keeps using Node's vendored undici, which does not duplicate the header. Verified via `bunx @totto2727/bw@0.1.5 markdown --url ...` → 200.

## Reusable insight

- `@effect/platform-node` package root currently has a hard side-effect of loading `undici` even for consumers that only want `FetchHttpClient`. Prefer deep imports (`@effect/platform-node/NodeRuntime`, `/NodeServices`, etc.) when not using `NodeHttpClient.layerUndici`.
- `HttpBody.{uint8Array,text,jsonUnsafe}` always carry `contentLength`, and `HttpClientRequest.setBody` always promotes that to a `content-length` header. The fetch spec marks `content-length` as a forbidden header — fetch backends compute it themselves — so this manual header is redundant at best and harmful at worst (the dual-Content-Length scenario above).
- Same root-cause pattern was reported against commercetools-sdk-typescript ([issue #1262](https://github.com/commercetools/commercetools-sdk-typescript/issues/1262), 2026-05-05) and acknowledged by undici ([PR #5060](https://github.com/nodejs/undici/pull/5060)).

## Action items

- [ ] **File upstream issue against Effect-TS / effect-smol** describing the duplicate-Content-Length scenario and proposing one of:
  - Skip the `content-length` header in `HttpClientRequest.setBody` for body shapes whose length is known (let the backend compute it).
  - OR remove the `Undici.js` re-export from `@effect/platform-node` package root so `import { NodeRuntime } from '@effect/platform-node'` does not drag npm undici as a side-effect (breaking, deferrable).
- [ ] No action needed against undici (issue #1262 is the canonical thread).

## Scope note

`mdt` / `wt` / `c-plugin` use `@effect/platform-node` with the same shallow root import but do not perform any HTTP requests, so they are unaffected. No defensive change required there.
