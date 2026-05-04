/* oxlint-disable rules/force-predicate, typescript-eslint/no-unsafe-type-assertion -- this package is consumer-runtime only and avoids depending on `effect`; the type assertions below bridge between remix/ui's internal types and our public API. */
import type { MiddlewareHandler } from 'hono'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

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

export interface RemixRendererOptions<TProps extends object> {
  fetcher: typeof fetch
  wrap?: (content: RemixNode, props: TProps) => RemixNode
  resolveClientEntry?: ResolveClientEntry
}

const DEFAULT_ASSET_PREFIX = '/assets/'

const defaultResolveClientEntry: ResolveClientEntry = (entryId, component) => {
  const hashIndex = entryId.lastIndexOf('#')
  const rawHref = hashIndex === -1 ? entryId : entryId.slice(0, hashIndex)
  const fallbackName = component.name ?? ''
  const exportName = hashIndex === -1 ? fallbackName : entryId.slice(hashIndex + 1) || fallbackName
  const href = rawHref.startsWith(DEFAULT_ASSET_PREFIX) ? rawHref.slice(DEFAULT_ASSET_PREFIX.length - 1) : rawHref
  return { exportName, href }
}

export const remixRenderer = <TProps extends object = Record<string, never>>(
  options: RemixRendererOptions<TProps>,
): MiddlewareHandler => {
  const wrap = options.wrap ?? ((content) => content)
  const resolveClientEntry = options.resolveClientEntry ?? defaultResolveClientEntry

  return (c, next) => {
    c.setRenderer(((content: RemixNode, props?: TProps) => {
      const stream = renderToStream(wrap(content, props ?? ({} as TProps)), {
        frameSrc: c.req.url,
        resolveClientEntry: resolveClientEntry as never,
        async resolveFrame(src, target) {
          const headers = new Headers({ accept: 'text/html' })
          const cookie = c.req.header('cookie')
          if (cookie !== undefined && cookie !== '') {
            headers.set('cookie', cookie)
          }
          if (target !== undefined && target !== '') {
            headers.set('x-remix-target', target)
          }
          const response = await options.fetcher(new Request(new URL(src, c.req.url), { headers }))
          return response.body ?? response.text()
        },
      })

      return new Response(stream, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      })
    }) as never)

    return next()
  }
}
