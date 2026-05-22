import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateMilestoneStatus } from '#@/lib/milestone.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const milestoneSetStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
    value: Argument.choice('status', ['planned', 'active', 'completed', 'blocked', 'cancelled']),
  },
  ({ roadmapId, targetId: milestoneId, value: status }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const now = yield* DateTime.now
      const result = yield* updateMilestoneStatus({
        dir,
        milestoneId,
        now,
        roadmapId,
        status,
      }).pipe(
        Effect.catchTags({
          MilestoneNotFoundError: (error) =>
            failWith(`milestone "${error.milestoneId}" not found in ${error.roadmapId}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId} status to ${status}`)
      }
    }),
).pipe(Command.withDescription("Set a milestone's status (planned | active | completed | blocked | cancelled)"))
