import { Console, DateTime, Effect, Option } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { addMilestone } from '#@/lib/milestone.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

const milestoneBase = Command.make('milestone').pipe(
  Command.withDescription('Manage milestones under a roadmap'),
  Command.withSharedFlags({
    dir: Flag.string('dir').pipe(
      Flag.withAlias('d'),
      Flag.withDefault('docs/roadmap'),
      Flag.withDescription('Base directory under which <roadmap-id>/milestones/<id>.md is created'),
    ),
  }),
)

const milestoneNewCommand = Command.make(
  'new',
  {
    roadmapId: Argument.string('roadmap-id'),
    milestoneId: Argument.string('milestone-id'),
    title: Flag.string('title').pipe(
      Flag.withAlias('t'),
      Flag.optional,
      Flag.withDescription('Human-readable title (defaults to <milestone-id>)'),
    ),
  },
  ({ milestoneId, roadmapId, title }) =>
    Effect.gen(function* () {
      const { dir } = yield* milestoneBase
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

      if (result !== null) {
        yield* Console.log(`Created ${result.milestonePath}`)
        yield* Console.log(`Updated ${result.progressPath}`)
      }
    }),
).pipe(Command.withDescription('Add a milestone to docs/roadmap/<roadmap-id>/progress.yaml'))

export const milestoneCommand = milestoneBase.pipe(Command.withSubcommands([milestoneNewCommand]))
