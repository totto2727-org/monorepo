import type { MiddlewareHandler } from 'hono'

/**
 * Structural type that matches the `AssetServer` produced by
 * `remix/assets#createAssetServer`. Declared structurally so this module
 * can be imported by Workers consumers without pulling `remix/assets`
 * (which depends on Node's `fs` / `path`) into the bundle.
 */
export interface AssetServer {
  fetch(request: Request): Promise<Response | null>
}

/**
 * Wraps a Remix `AssetServer` (typically created via
 * `createAssetServer({...})` from `remix/assets`) as a Hono middleware.
 *
 * If the asset server returns a response, that response short-circuits
 * the request. Otherwise the middleware falls through to the next
 * handler.
 *
 * Mount it at the asset basePath, matching what was passed to
 * `createAssetServer`:
 *
 * ```ts
 * import { createAssetServer } from 'remix/assets'
 * import { remixAssetServer } from 'hono-remix-middleware'
 *
 * const assets = createAssetServer({ basePath: '/assets', ... })
 * app.use('/assets/*', remixAssetServer(assets))
 * ```
 *
 * Intended for the Native pattern (no bundler — tsx / bun / deno
 * directly executes TypeScript). Vite-bundled apps should serve the
 * built `dist/client/` instead (Workers Assets binding or
 * `serveStatic`).
 */
export const remixAssetServer =
  (assetServer: AssetServer): MiddlewareHandler =>
  async (ctx, next) => {
    const response = await assetServer.fetch(ctx.req.raw)
    if (response) {
      return response
    }
    await next()
    return ctx.res
  }
