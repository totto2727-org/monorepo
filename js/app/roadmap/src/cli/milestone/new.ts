import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { addMilestone } from '#@/lib/milestone.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

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
      const { dir } = yield* rootCommand
      const resolvedTitle = Option.getOrElse(title, () => milestoneId)
      const now = yield* DateTime.now
      const result = yield* addMilestone({
        dir,
        milestoneId,
        now,
        roadmapId,
        title: resolvedTitle,
      }).pipe(
        Effect.catchTags({
          MilestoneAlreadyExistsError: (error) =>
            failWith(`milestone "${error.milestoneId}" already exists in ${error.roadmapId}`),
          MilestoneFileExistsError: (error) => failWith(`${error.path} already exists`),
          MilestoneWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Created ${result.milestonePath}`)
        yield* Console.log(`Updated ${result.progressPath}`)
      }
    }),
).pipe(Command.withDescription('Add a milestone to docs/roadmap/<roadmap-id>/progress.yaml'))
