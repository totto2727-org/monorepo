import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateMilestoneStatus } from '#@/lib/milestone.ts'

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
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateMilestoneStatus({
        dir,
        milestoneId,
        now,
        roadmapId,
        status,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId} status to ${status}`)
      }
    }),
).pipe(Command.withDescription("Set a milestone's status (planned | active | completed | blocked | cancelled)"))
