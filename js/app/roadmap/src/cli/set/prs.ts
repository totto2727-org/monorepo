import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { updateRoadmapPrs } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const setPrsCommand = Command.make(
  'prs',
  {
    roadmapId: Argument.string('roadmap-id'),
    value: Argument.string('pr').pipe(Argument.atLeast(1)),
  },
  ({ roadmapId, value: prs }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand
      const now = yield* DateTime.now
      const result = yield* updateRoadmapPrs({
        dir,
        now,
        prs,
        roadmapId,
      }).pipe(
        Effect.catchTags({
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId} PRs to: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a roadmap's linked PRs"))
