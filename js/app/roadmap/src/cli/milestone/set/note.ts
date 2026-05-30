import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateMilestoneNote } from '#@/lib/milestone.ts'

export const milestoneSetNoteCommand = Command.make(
  'note',
  {
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
    value: Argument.string('note'),
  },
  ({ roadmapId, targetId: milestoneId, value: note }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateMilestoneNote({
        dir,
        milestoneId,
        note,
        now,
        roadmapId,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Set ${roadmapId}/${milestoneId} note to: ${note}`)
      }
    }),
).pipe(Command.withDescription("Set a milestone's note"))
