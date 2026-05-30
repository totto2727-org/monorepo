import { Array, Console, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { readProgressFile } from '#@/lib/progress.ts'

const formatList = (items: readonly string[]): string =>
  Array.isReadonlyArrayEmpty(items) ? '(none)' : items.join(', ')

export const milestoneStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
  },
  ({ roadmapId, targetId: milestoneId }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const progress = yield* readProgressFile({ dir, roadmapId })

      const milestone = progress.milestones.find((m) => m.id === milestoneId)
      if (Predicate.isNullish(milestone)) {
        yield* Effect.fail(new Error(`milestone "${milestoneId}" not found in ${roadmapId}`))
        return
      }

      yield* Console.log(`milestone_id:         ${milestone.id}`)
      yield* Console.log(`roadmap_id:           ${progress.roadmap_id}`)
      yield* Console.log(`title:                ${milestone.title}`)
      yield* Console.log(`status:               ${milestone.status}`)
      yield* Console.log(`depends_on:           ${formatList(milestone.depends_on)}`)
      yield* Console.log(`workflow_identifiers: ${formatList(milestone.workflow_identifiers)}`)
      yield* Console.log(`prs:                  ${formatList(milestone.prs)}`)
      yield* Console.log(`notes:                ${milestone.notes ?? '(none)'}`)
    }),
).pipe(Command.withDescription('Show detailed status of one milestone'))
