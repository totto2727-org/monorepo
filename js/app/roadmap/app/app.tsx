import { NodeServices } from '@effect/platform-node'
import { Effect, Predicate, String } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

import { listRoadmaps } from '#@/lib/progress.ts'

import { Document } from './ui/document.tsx'
import { Kanban } from './ui/kanban.tsx'
import type { KanbanRoadmap } from './ui/kanban.tsx'

const renderRemix = (content: RemixNode, frameSrc: string): Response => {
  const stream = renderToStream(content, { frameSrc })
  return new Response(stream, {
    headers: { 'content-type': 'text/html; charset=utf-8' },
  })
}

const loadRoadmaps = (dir: string): Promise<KanbanRoadmap[]> =>
  Effect.runPromise(
    listRoadmaps(dir).pipe(
      Effect.map((roadmaps) =>
        roadmaps.map(
          (r): KanbanRoadmap => ({
            id: r.roadmap_id,
            milestones: r.milestones.map((m) => ({
              depends_on: m.depends_on,
              id: m.id,
              notes: m.notes,
              prs: m.prs,
              status: m.status,
              title: m.title,
            })),
            prs: r.prs,
            status: r.status,
            title: r.title,
          }),
        ),
      ),
      Effect.orElseSucceed((): KanbanRoadmap[] => []),
      Effect.provide(NodeServices.layer),
    ),
  )

const parseShow = (showParam: string | undefined): string[] => {
  if (Predicate.isNullish(showParam)) {
    return []
  }
  if (String.isEmpty(showParam)) {
    return ['']
  }
  return showParam.split(',')
}

export interface AppOptions {
  dir: string
}

export const createApp = (options: AppOptions): Hono => {
  const app = new Hono()

  app
    .use(logger())
    .use(contextStorage())
    .get('/', async (c) => {
      const roadmaps = await loadRoadmaps(options.dir)
      const show = parseShow(c.req.query('show'))

      return renderRemix(
        <Document title='Roadmap Kanban'>
          <Kanban roadmaps={roadmaps} show={show} />
        </Document>,
        c.req.url,
      )
    })

  return app
}
