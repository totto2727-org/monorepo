import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

import app from '../app.ts'

const ASSET_PREFIX = '/assets/'

export function render(node: RemixNode, request: Request, init?: ResponseInit) {
  const stream = renderToStream(node, {
    frameSrc: request.url,
    resolveClientEntry(entryId, component) {
      const hashIndex = entryId.lastIndexOf('#')
      const rawHref = hashIndex === -1 ? entryId : entryId.slice(0, hashIndex)
      const exportName =
        hashIndex === -1 ? (component.name ?? '') : (entryId.slice(hashIndex + 1) ?? component.name ?? '')
      const href = rawHref.startsWith(ASSET_PREFIX) ? rawHref.slice(ASSET_PREFIX.length - 1) : rawHref
      return { exportName, href }
    },
    async resolveFrame(src, target) {
      const headers = new Headers({ accept: 'text/html' })
      const cookie = request.headers.get('cookie')
      if (cookie) {
        headers.set('cookie', cookie)
      }
      if (target) {
        headers.set('x-remix-target', target)
      }

      const response = await app.fetch(new Request(new URL(src, request.url), { headers }))
      return response.body ?? response.text()
    },
  })

  const headers = new Headers(init?.headers)
  if (!headers.has('Content-Type')) {
    headers.set('Content-Type', 'text/html; charset=utf-8')
  }

  return new Response(stream, { ...init, headers })
}
