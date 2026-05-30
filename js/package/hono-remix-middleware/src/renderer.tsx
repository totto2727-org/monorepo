import { Predicate, String } from 'effect'
import type { MiddlewareHandler } from 'hono'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'
import type { RenderToStreamOptions } from 'remix/ui/server'

declare module 'hono' {
  interface ContextRenderer {
    (content: RemixNode): Response
    readonly marker?: never
  }
}

export interface ResolvedClientEntry {
  exportName: string
  href: string
}

/**
 * Hook for translating a `clientEntry()` ID into the `moduleUrl` /
 * `exportName` pair the SSR should embed in the hydration data.
 *
 * The `component` argument matches what `remix/ui/server`'s
 * `renderToStream` passes — typed loosely as `{ name?: string }` so
 * consumers don't need to depend on Remix's internal `EntryComponent`
 * type.
 */
export type ResolveClientEntry = (entryId: string, component: { name?: string }) => ResolvedClientEntry

export interface RemixRendererOptions {
  fetcher: typeof fetch
  resolveClientEntry?: RenderToStreamOptions['resolveClientEntry']
}

const DEFAULT_ASSET_PREFIX = '/assets/'

const defaultResolveClientEntry: NonNullable<RenderToStreamOptions['resolveClientEntry']> = (entryId, component) => {
  const hashIndex = entryId.lastIndexOf('#')
  const rawHref = hashIndex === -1 ? entryId : entryId.slice(0, hashIndex)
  const fallbackName = component.name ?? ''
  const exportName = hashIndex === -1 ? fallbackName : entryId.slice(hashIndex + 1) || fallbackName
  const href = rawHref.startsWith(DEFAULT_ASSET_PREFIX) ? rawHref.slice(DEFAULT_ASSET_PREFIX.length - 1) : rawHref
  return { exportName, href }
}

export const remixRenderer = (options: RemixRendererOptions): MiddlewareHandler => {
  const resolveClientEntry = options.resolveClientEntry ?? defaultResolveClientEntry

  return (c, next) => {
    c.setRenderer((content) => {
      const stream = renderToStream(content, {
        frameSrc: c.req.url,
        resolveClientEntry,
        async resolveFrame(src, target) {
          const headers = new Headers({ accept: 'text/html' })
          const cookie = c.req.header('cookie')
          if (Predicate.isNotNullish(cookie) && String.isNonEmpty(cookie)) {
            headers.set('cookie', cookie)
          }
          if (Predicate.isString(target) && String.isNonEmpty(target)) {
            headers.set('x-remix-target', target)
          }
          const response = await options.fetcher(new Request(new URL(src, c.req.url), { headers }))
          return await (response.body ?? response.text())
        },
      })

      return new Response(stream, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      })
    })

    return next()
  }
}
