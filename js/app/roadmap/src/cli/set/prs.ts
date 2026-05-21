import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { updateRoadmapPrs } from '#@/lib/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

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
      const { dir } = yield* rootCommand
      const now = yield* DateTime.now
      const result = yield* updateRoadmapPrs({
        append,
        dir,
        now,
        prs,
        roadmapId,
      }).pipe(
        Effect.catchTags({
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        const action = append ? 'Appended' : 'Set'
        yield* Console.log(`${action} ${roadmapId} PRs: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a roadmap's linked PRs"))
