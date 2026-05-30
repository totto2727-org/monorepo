import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateTaskStatus } from '#@/lib/task.ts'

export const taskSetStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
    targetId: Argument.string('task-id'),
    value: Argument.choice('status', ['planned', 'active', 'completed', 'blocked', 'cancelled']),
  },
  ({ roadmapId, scopeId: milestoneId, targetId: taskId, value: status }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateTaskStatus({
        dir,
        milestoneId,
        now,
        roadmapId,
        status,
        taskId,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId}/${taskId} status to ${status}`)
      }
    }),
).pipe(Command.withDescription("Set a task's status (planned | active | completed | blocked | cancelled)"))
