import { Array, Console, Effect } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { readProgressFile } from '#@/lib/progress.ts'

export const milestoneLsCommand = Command.make(
  'ls',
  {
    roadmapId: Argument.string('roadmap-id'),
  },
  ({ roadmapId }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const progress = yield* readProgressFile({ dir, roadmapId })

      if (Array.isReadonlyArrayEmpty(progress.milestones)) {
        yield* Console.log(`(no milestones in ${roadmapId})`)
        return
      }

      for (const m of progress.milestones) {
        const deps = Array.isReadonlyArrayEmpty(m.depends_on) ? '' : ` [depends on: ${m.depends_on.join(', ')}]`
        yield* Console.log(`- ${m.id} (${m.status}) ${m.title}${deps}`)
      }
    }),
).pipe(Command.withDescription('List milestones in a roadmap'))
