import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { addTask } from '#@/lib/task.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const taskNewCommand = Command.make(
  'new',
  {
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
    targetId: Argument.string('task-id'),
    title: Flag.string('title').pipe(
      Flag.withAlias('t'),
      Flag.optional,
      Flag.withDescription('Human-readable title (defaults to <task-id>)'),
    ),
  },
  ({ roadmapId, scopeId: milestoneId, targetId: taskId, title }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const resolvedTitle = Option.getOrElse(title, () => taskId)
      const now = yield* DateTime.now
      const result = yield* addTask({
        dir,
        milestoneId,
        now,
        roadmapId,
        taskId,
        title: resolvedTitle,
      }).pipe(
        Effect.catchTags({
          MilestoneNotFoundError: (error) =>
            failWith(`milestone "${error.milestoneId}" not found in ${error.roadmapId}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
          TaskAlreadyExistsError: (error) =>
            failWith(`task "${error.taskId}" already exists under ${error.roadmapId}/${error.milestoneId}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Added task ${roadmapId}/${milestoneId}/${taskId}`)
        yield* Console.log(`Updated ${result.progressPath}`)
      }
    }),
).pipe(Command.withDescription('Add a task under a milestone in docs/roadmap/<roadmap-id>/progress.yaml'))
