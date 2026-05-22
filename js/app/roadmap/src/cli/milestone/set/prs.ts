import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { updateMilestonePrs } from '#@/lib/milestone.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const milestoneSetPrsCommand = Command.make(
  'prs',
  {
    append: Flag.boolean('append').pipe(
      Flag.withAlias('a'),
      Flag.withDescription('Append to existing PRs instead of replacing (duplicates are dropped)'),
    ),
    roadmapId: Argument.string('roadmap-id'),
    targetId: Argument.string('milestone-id'),
    value: Argument.string('pr').pipe(Argument.atLeast(1)),
  },
  ({ append, roadmapId, targetId: milestoneId, value: prs }) =>
    Effect.gen(function* () {
      const { dir } = yield* rootCommand
      const now = yield* DateTime.now
      const result = yield* updateMilestonePrs({
        append,
        dir,
        milestoneId,
        now,
        prs,
        roadmapId,
      }).pipe(
        Effect.catchTags({
          MilestoneNotFoundError: (error) =>
            failWith(`milestone "${error.milestoneId}" not found in ${error.roadmapId}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        const action = append ? 'Appended' : 'Set'
        yield* Console.log(`${action} ${roadmapId}/${milestoneId} PRs: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a milestone's linked PRs"))
