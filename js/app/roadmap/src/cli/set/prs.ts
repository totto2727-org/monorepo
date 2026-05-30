import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateRoadmapPrs } from '#@/lib/progress.ts'

export const setPrsCommand = Command.make(
  'prs',
  {
    append: Flag.boolean('append').pipe(
      Flag.withAlias('a'),
      Flag.withDescription('Append to existing PRs instead of replacing (duplicates are dropped)'),
    ),
    roadmapId: Argument.string('roadmap-id'),
    value: Argument.string('pr').pipe(Argument.atLeast(1)),
  },
  ({ append, roadmapId, value: prs }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateRoadmapPrs({
        append,
        dir,
        now,
        prs,
        roadmapId,
      })

      if (Predicate.isNotNullish(result)) {
        const action = append ? 'Appended' : 'Set'
        yield* Console.log(`${action} ${roadmapId} PRs: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a roadmap's linked PRs"))
