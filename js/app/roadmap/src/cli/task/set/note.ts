import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateTaskNote } from '#@/lib/task.ts'

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
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateTaskNote({
        dir,
        milestoneId,
        note,
        now,
        roadmapId,
        taskId,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId}/${taskId} note to: ${note}`)
      }
    }),
).pipe(Command.withDescription("Set a task's note"))
