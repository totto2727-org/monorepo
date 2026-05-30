import { Array, Console, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { findMilestone } from '#@/lib/milestone.ts'
import { readProgressFile } from '#@/lib/progress.ts'

export const taskLsCommand = Command.make(
  'ls',
  {
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
  },
  ({ roadmapId, scopeId: milestoneId }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const progress = yield* readProgressFile({ dir, roadmapId })

      const milestone = findMilestone(progress, milestoneId)
      if (Predicate.isNullish(milestone)) {
        yield* Effect.fail(new Error(`milestone "${milestoneId}" not found in ${roadmapId}`))
        return
      }

      if (Array.isReadonlyArrayEmpty(milestone.tasks)) {
        yield* Console.log(`(no tasks in ${roadmapId}/${milestoneId})`)
        return
      }

      for (const t of milestone.tasks) {
        yield* Console.log(`- ${t.id} (${t.status}) ${t.title}`)
      }
    }),
).pipe(Command.withDescription('List tasks under a milestone'))
