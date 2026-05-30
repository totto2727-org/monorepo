import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateTaskPrs } from '#@/lib/task.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

export const taskSetPrsCommand = Command.make(
  'prs',
  {
    append: Flag.boolean('append').pipe(
      Flag.withAlias('a'),
      Flag.withDescription('Append to existing PRs instead of replacing (duplicates are dropped)'),
    ),
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
    targetId: Argument.string('task-id'),
    value: Argument.string('pr').pipe(Argument.atLeast(1)),
  },
  ({ append, roadmapId, scopeId: milestoneId, targetId: taskId, value: prs }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const now = yield* DateTime.now
      const result = yield* updateTaskPrs({
        append,
        dir,
        milestoneId,
        now,
        prs,
        roadmapId,
        taskId,
      }).pipe(
        Effect.catchTags({
          MilestoneNotFoundError: (error) =>
            failWith(`milestone "${error.milestoneId}" not found in ${error.roadmapId}`),
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
          ProgressWriteError: (error) => failWith(`failed to write ${error.path}: ${error.message}`),
          TaskNotFoundError: (error) =>
            failWith(`task "${error.taskId}" not found under ${error.roadmapId}/${error.milestoneId}`),
        }),
      )

      if (Predicate.isNotNullish(result)) {
        const action = append ? 'Appended' : 'Set'
        yield* Console.log(`${action} ${roadmapId}/${milestoneId}/${taskId} PRs: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a task's linked PRs"))
