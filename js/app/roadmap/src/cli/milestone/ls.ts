import { Array, Console, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { readProgressFile } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const milestoneLsCommand = Command.make(
  'ls',
  {
    roadmapId: Argument.string('roadmap-id'),
  },
  ({ roadmapId }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand
      const progress = yield* readProgressFile({ dir, roadmapId }).pipe(
        Effect.catchTags({
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
        }),
      )

      if (Predicate.isNullish(progress)) {
        return
      }

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
