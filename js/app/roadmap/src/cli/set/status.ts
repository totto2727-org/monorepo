import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { updateRoadmapStatus } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const setStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    status: Argument.choice('status', ['planned', 'active', 'completed']),
  },
  ({ roadmapId, status }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand
      const now = yield* DateTime.now
      const result = yield* updateRoadmapStatus({
        dir,
        now,
        roadmapId,
        status,
      }).pipe(
        Effect.catchTags({
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId} status to ${status}`)
      }
    }),
).pipe(Command.withDescription("Set a roadmap's status (planned | active | completed)"))
