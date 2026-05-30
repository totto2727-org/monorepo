import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { initProgressFile } from '#@/lib/progress.ts'

export const newCommand = Command.make(
  'new',
  {
    roadmapId: Argument.string('id'),
    title: Flag.string('title').pipe(
      Flag.withAlias('t'),
      Flag.optional,
      Flag.withDescription('Human-readable title (defaults to <id>)'),
    ),
  },
  ({ roadmapId, title }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const resolvedTitle = Option.getOrElse(title, () => roadmapId)
      const now = yield* DateTime.now
      const result = yield* initProgressFile({
        dir,
        now,
        roadmapId,
        title: resolvedTitle,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Created ${result.path}`)
      }
    }),
).pipe(Command.withDescription('Initialise docs/roadmap/<id>/progress.yaml'))
