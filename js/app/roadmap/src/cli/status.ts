import { Array, Console, DateTime, Effect } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import type { Milestone } from '#@/feature/schema/current.ts'
import { readProgressFile } from '#@/lib/progress.ts'

const countCompleted = (milestones: readonly Milestone[]): number =>
  milestones.filter((m) => m.status === 'completed').length

const formatList = (items: readonly string[]): string =>
  Array.isReadonlyArrayEmpty(items) ? '(none)' : items.join(', ')

export const statusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
  },
  ({ roadmapId }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const progress = yield* readProgressFile({ dir, roadmapId })

      const completed = countCompleted(progress.milestones)
      yield* Console.log(`roadmap_id: ${progress.roadmap_id}`)
      yield* Console.log(`title:      ${progress.title}`)
      yield* Console.log(`status:     ${progress.status}`)
      yield* Console.log(`created_at: ${DateTime.formatIso(progress.created_at)}`)
      yield* Console.log(`updated_at: ${DateTime.formatIso(progress.updated_at)}`)
      yield* Console.log(`prs:        ${formatList(progress.prs)}`)
      yield* Console.log('')
      yield* Console.log(`milestones (${completed}/${progress.milestones.length} completed):`)
      if (Array.isReadonlyArrayEmpty(progress.milestones)) {
        yield* Console.log('  (none)')
        return
      }
      for (const m of progress.milestones) {
        yield* Console.log(`  - ${m.id} (${m.status}) ${m.title}`)
      }
    }),
).pipe(Command.withDescription('Show detailed status of one roadmap'))
