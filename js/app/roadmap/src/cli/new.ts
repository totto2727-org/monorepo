import { Console, DateTime, Effect, Option } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { initProgressFile } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

const runNew = (roadmapId: string, title: Option.Option<string>, dir: string) =>
  Effect.gen(function* () {
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

    if (result !== null) {
      yield* Console.log(`Created ${result.path}`)
    }
  })

export const newCommand = Command.make(
  'new',
  {
    dir: Flag.string('dir').pipe(
      Flag.withAlias('d'),
      Flag.withDefault('docs/roadmap'),
      Flag.withDescription('Base directory under which <id>/progress.yaml is created'),
    ),
    roadmapId: Argument.string('id'),
    title: Flag.string('title').pipe(
      Flag.withAlias('t'),
      Flag.optional,
      Flag.withDescription('Human-readable title (defaults to <id>)'),
    ),
  },
  ({ dir, roadmapId, title }) => runNew(roadmapId, title, dir),
).pipe(Command.withDescription('Initialise docs/roadmap/<id>/progress.yaml'))
