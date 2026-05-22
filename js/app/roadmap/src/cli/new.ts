import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { initProgressFile } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

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
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const resolvedTitle = Option.getOrElse(title, () => roadmapId)
      const now = yield* DateTime.now
      const result = yield* initProgressFile({
        dir,
        now,
        roadmapId,
        title: resolvedTitle,
      }).pipe(
        Effect.catchTags({
          ProgressFileExistsError: (error) => failWith(`${error.path} already exists`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Created ${result.path}`)
      }
    }),
).pipe(Command.withDescription('Initialise docs/roadmap/<id>/progress.yaml'))
