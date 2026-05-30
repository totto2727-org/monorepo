import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateRoadmapStatus } from '#@/lib/progress.ts'

export const setStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    status: Argument.choice('status', ['planned', 'active', 'completed']),
  },
  ({ roadmapId, status }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateRoadmapStatus({
        dir,
        now,
        roadmapId,
        status,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId} status to ${status}`)
      }
    }),
).pipe(Command.withDescription("Set a roadmap's status (planned | active | completed)"))
