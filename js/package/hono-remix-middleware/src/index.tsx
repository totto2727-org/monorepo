import type { MiddlewareHandler } from 'hono'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

export type Fetcher = (request: Request) => Promise<Response>

export interface ResolvedClientEntry {
  exportName: string
  href: string
}

export type ResolveClientEntry = (entryId: string, component: { name?: string }) => ResolvedClientEntry

export interface RemixRendererOptions<TProps extends object> {
  fetcher: Fetcher
  wrap?: (content: RemixNode, props: TProps) => RemixNode
  resolveClientEntry?: ResolveClientEntry
}

const DEFAULT_ASSET_PREFIX = '/assets/'

const defaultResolveClientEntry: ResolveClientEntry = (entryId, component) => {
  const hashIndex = entryId.lastIndexOf('#')
  const rawHref = hashIndex === -1 ? entryId : entryId.slice(0, hashIndex)
  const fallbackName = component.name ?? ''
  const exportName = hashIndex === -1 ? fallbackName : (entryId.slice(hashIndex + 1) || fallbackName)
  const href = rawHref.startsWith(DEFAULT_ASSET_PREFIX)
    ? rawHref.slice(DEFAULT_ASSET_PREFIX.length - 1)
    : rawHref
  return { exportName, href }
}

export const remixRenderer = <TProps extends object = Record<string, never>>(
  options: RemixRendererOptions<TProps>,
): MiddlewareHandler => {
  const wrap = options.wrap ?? ((content) => content)
  const resolveClientEntry = options.resolveClientEntry ?? defaultResolveClientEntry

  return async (c, next) => {
    c.setRenderer((content, props) => {
      const stream = renderToStream(wrap(content as RemixNode, (props ?? {}) as TProps), {
        frameSrc: c.req.url,
        resolveClientEntry,
        async resolveFrame(src, target) {
          const headers = new Headers({ accept: 'text/html' })
          const cookie = c.req.header('cookie')
          if (cookie) headers.set('cookie', cookie)
          if (target) headers.set('x-remix-target', target)
          const response = await options.fetcher(new Request(new URL(src, c.req.url), { headers }))
          return response.body ?? response.text()
        },
      })

      return new Response(stream, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      })
    })

    return next()
  }
}
