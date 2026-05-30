import { Array, Console, Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import type { Milestone } from '#@/feature/schema/current.ts'
import { listRoadmaps } from '#@/lib/progress.ts'

const countCompleted = (milestones: readonly Milestone[]): number =>
  milestones.filter((m) => m.status === 'completed').length

export const lsCommand = Command.make('ls', {}, () =>
  Effect.gen(function* () {
    const { dir: relativeDir } = yield* rootCommand
    const { dir } = yield* resolveDirOrFail(relativeDir)
    const roadmaps = yield* listRoadmaps(dir)

    if (Array.isReadonlyArrayEmpty(roadmaps)) {
      yield* Console.log(`(no roadmaps found under ${dir})`)
      return
    }

    for (const r of roadmaps) {
      const completed = countCompleted(r.milestones)
      yield* Console.log(
        `- ${r.roadmap_id} (${r.status}) ${r.title} \u2014 milestones: ${completed}/${r.milestones.length}`,
      )
    }
  }),
).pipe(Command.withDescription('List roadmaps under <dir>'))
