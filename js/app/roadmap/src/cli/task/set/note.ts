import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateTaskNote } from '#@/lib/task.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const taskSetNoteCommand = Command.make(
  'note',
  {
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
    targetId: Argument.string('task-id'),
    value: Argument.string('note'),
  },
  ({ roadmapId, scopeId: milestoneId, targetId: taskId, value: note }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const now = yield* DateTime.now
      const result = yield* updateTaskNote({
        dir,
        milestoneId,
        note,
        now,
        roadmapId,
        taskId,
      }).pipe(
        Effect.catchTags({
          MilestoneNotFoundError: (error) =>
            failWith(`milestone "${error.milestoneId}" not found in ${error.roadmapId}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
          TaskNotFoundError: (error) =>
            failWith(`task "${error.taskId}" not found under ${error.roadmapId}/${error.milestoneId}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId}/${taskId} note to: ${note}`)
      }
    }),
).pipe(Command.withDescription("Set a task's note"))
