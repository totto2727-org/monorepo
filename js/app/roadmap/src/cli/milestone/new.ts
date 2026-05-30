import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { addMilestone } from '#@/lib/milestone.ts'

export const milestoneNewCommand = Command.make(
  'new',
  {
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
    title: Flag.string('title').pipe(
      Flag.withAlias('t'),
      Flag.optional,
      Flag.withDescription('Human-readable title (defaults to <milestone-id>)'),
    ),
  },
  ({ roadmapId, targetId: milestoneId, title }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const resolvedTitle = Option.getOrElse(title, () => milestoneId)
      const now = yield* DateTime.now
      const result = yield* addMilestone({
        dir,
        milestoneId,
        now,
        roadmapId,
        title: resolvedTitle,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Created ${result.milestonePath}`)
        yield* Console.log(`Updated ${result.progressPath}`)
      }
    }),
).pipe(Command.withDescription('Add a milestone to docs/roadmap/<roadmap-id>/progress.yaml'))
