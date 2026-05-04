import type { MiddlewareHandler } from 'hono'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

import { Layout } from '../ui/layout.tsx'

declare module 'hono' {
  interface ContextRenderer {
    (content: RemixNode, props?: { title?: string }): Response
  }
}

const ASSET_PREFIX = '/assets/'

type Fetcher = (request: Request) => Promise<Response>

export const remixRenderer = (fetcher: Fetcher): MiddlewareHandler => async (c, next) => {
  c.setRenderer((content, props = {}) => {
    const stream = renderToStream(<Layout title={props.title}>{content}</Layout>, {
      frameSrc: c.req.url,
      resolveClientEntry(entryId, component) {
        const hashIndex = entryId.lastIndexOf('#')
        const rawHref = hashIndex === -1 ? entryId : entryId.slice(0, hashIndex)
        const exportName = hashIndex === -1 ? (component.name ?? '') : (entryId.slice(hashIndex + 1) || (component.name ?? ''))
        const href = rawHref.startsWith(ASSET_PREFIX) ? rawHref.slice(ASSET_PREFIX.length - 1) : rawHref
        return { exportName, href }
      },
      async resolveFrame(src, target) {
        const headers = new Headers({ accept: 'text/html' })
        const cookie = c.req.header('cookie')
        if (cookie) headers.set('cookie', cookie)
        if (target) headers.set('x-remix-target', target)
        const response = await fetcher(new Request(new URL(src, c.req.url), { headers }))
        return response.body ?? response.text()
      },
    })

    return new Response(stream, {
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
    })
  })

  return next()
}
