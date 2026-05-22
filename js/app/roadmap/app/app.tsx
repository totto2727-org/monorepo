import { NodeServices } from '@effect/platform-node'
import { Effect, Predicate, String } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'
import type { RemixNode } from 'remix/ui'
import { renderToStream } from 'remix/ui/server'

import type { Worktree } from '#@/lib/git.ts'
import { listRoadmapsAcrossWorktrees } from '#@/lib/progress.ts'
import type { Milestone, RoadmapProgress } from '#@/schema/progress.ts'

import { Document } from './ui/document.tsx'
import { Kanban } from './ui/kanban.tsx'
import type { KanbanMilestone, KanbanRoadmap, MilestoneStatus, WorktreeView } from './ui/kanban.tsx'

const renderRemix = (content: RemixNode, frameSrc: string): Response => {
  const stream = renderToStream(content, { frameSrc })
  return new Response(stream, {
    headers: { 'content-type': 'text/html; charset=utf-8' },
  })
}

const WORKTREE_PALETTE = [
  '#0ea5e9',
  '#ec4899',
  '#f59e0b',
  '#10b981',
  '#8b5cf6',
  '#ef4444',
  '#14b8a6',
  '#a855f7',
  '#84cc16',
  '#f97316',
] as const satisfies readonly string[]

const buildWorktreeViews = (worktrees: readonly Worktree[]): WorktreeView[] =>
  worktrees.map((w, i) => ({
    color: WORKTREE_PALETTE[i % WORKTREE_PALETTE.length] ?? '#94a3b8',
    id: w.id,
    isMain: w.isMain,
    label: w.branch ?? w.id,
  }))

const milestoneContentKey = (m: Milestone): string =>
  JSON.stringify({
    depends_on: [...m.depends_on],
    notes: m.notes,
    prs: [...m.prs],
    status: m.status,
    title: m.title,
  })

interface RawRoadmap {
  worktreeId: string
  roadmap: RoadmapProgress
}

const buildRoadmapData = (raws: readonly RawRoadmap[]): KanbanRoadmap[] => {
  const byRoadmap = new Map<string, RawRoadmap[]>()
  for (const r of raws) {
    const list = byRoadmap.get(r.roadmap.roadmap_id) ?? []
    list.push(r)
    byRoadmap.set(r.roadmap.roadmap_id, list)
  }
  const result: KanbanRoadmap[] = []
  for (const [roadmapId, group] of byRoadmap) {
    const title = group[0]?.roadmap.title ?? roadmapId
    const worktreeIds = group.map((g) => g.worktreeId)
    const milestoneGroups = new Map<string, { sample: Milestone; worktreeIds: string[] }>()
    for (const { roadmap, worktreeId } of group) {
      for (const m of roadmap.milestones) {
        const key = `${m.id}::${milestoneContentKey(m)}`
        const existing = milestoneGroups.get(key)
        if (Predicate.isNullish(existing)) {
          milestoneGroups.set(key, { sample: m, worktreeIds: [worktreeId] })
        } else {
          existing.worktreeIds.push(worktreeId)
        }
      }
    }
    const milestones: KanbanMilestone[] = []
    for (const { sample, worktreeIds: wids } of milestoneGroups.values()) {
      milestones.push({
        depends_on: sample.depends_on,
        id: sample.id,
        notes: sample.notes,
        prs: sample.prs,
        status: sample.status satisfies MilestoneStatus,
        title: sample.title,
        worktreeIds: wids,
      })
    }
    result.push({ id: roadmapId, milestones, title, worktreeIds })
  }
  return result.toSorted((a, b) => a.id.localeCompare(b.id))
}

interface LoadedData {
  worktrees: WorktreeView[]
  roadmaps: KanbanRoadmap[]
}

const loadData = (worktrees: readonly Worktree[], relativeDir: string): Promise<LoadedData> =>
  Effect.runPromise(
    listRoadmapsAcrossWorktrees(worktrees, relativeDir).pipe(
      Effect.map((wrs) => {
        const raws: RawRoadmap[] = []
        for (const { roadmaps, worktree } of wrs) {
          for (const roadmap of roadmaps) {
            raws.push({ roadmap, worktreeId: worktree.id })
          }
        }
        return {
          roadmaps: buildRoadmapData(raws),
          worktrees: buildWorktreeViews(worktrees),
        } satisfies LoadedData
      }),
      Effect.orElseSucceed(
        (): LoadedData => ({
          roadmaps: [],
          worktrees: buildWorktreeViews(worktrees),
        }),
      ),
      Effect.provide(NodeServices.layer),
    ),
  )

const parseFilter = (param: string | undefined): string[] => {
  if (Predicate.isNullish(param)) {
    return []
  }
  if (String.isEmpty(param)) {
    return ['']
  }
  return param.split(',')
}

export interface AppOptions {
  relativeDir: string
  worktrees: readonly Worktree[]
}

export const createApp = (options: AppOptions): Hono => {
  const app = new Hono()

  app
    .use(logger())
    .use(contextStorage())
    .get('/', async (c) => {
      const data = await loadData(options.worktrees, options.relativeDir)
      const showRoadmaps = parseFilter(c.req.query('roadmaps'))
      const showWorktrees = parseFilter(c.req.query('worktrees'))

      return renderRemix(
        <Document title='Roadmap Kanban'>
          <Kanban
            roadmaps={data.roadmaps}
            showRoadmaps={showRoadmaps}
            showWorktrees={showWorktrees}
            worktrees={data.worktrees}
          />
        </Document>,
        c.req.url,
      )
    })

  return app
}
