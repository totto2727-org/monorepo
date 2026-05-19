import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { updateMilestoneNote } from '#@/lib/milestone.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const milestoneSetNoteCommand = Command.make(
  'note',
  {
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
    value: Argument.string('note'),
  },
  ({ roadmapId, targetId: milestoneId, value: note }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand
      const now = yield* DateTime.now
      const result = yield* updateMilestoneNote({
        dir,
        milestoneId,
        note,
        now,
        roadmapId,
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
        yield* Console.log(`Set ${roadmapId}/${milestoneId} note to: ${note}`)
      }
    }),
).pipe(Command.withDescription("Set a milestone's note"))
