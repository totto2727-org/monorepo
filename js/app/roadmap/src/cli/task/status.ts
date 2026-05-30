import { Array, Console, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { findMilestone } from '#@/lib/milestone.ts'
import { readProgressFile } from '#@/lib/progress.ts'
import { findTask } from '#@/lib/task.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

const formatList = (items: readonly string[]): string =>
  Array.isReadonlyArrayEmpty(items) ? '(none)' : items.join(', ')

export const taskStatusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
    scopeId: Argument.string('milestone-id'),
    targetId: Argument.string('task-id'),
  },
  ({ roadmapId, scopeId: milestoneId, targetId: taskId }) =>
    Effect.gen(function* () {
      const { dir: relativeDir } = yield* rootCommand
      const resolved = yield* resolveDirOrFail(relativeDir)
      if (Predicate.isNullish(resolved)) {
        return
      }
      const { dir } = resolved
      const progress = yield* readProgressFile({ dir, roadmapId }).pipe(
        Effect.catchTags({
          ProgressFileNotFoundError: (error) => failWith(`${error.path} not found`),
          ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
          ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
        }),
      )

      if (Predicate.isNullish(progress)) {
        return
      }

      const milestone = findMilestone(progress, milestoneId)
      if (Predicate.isNullish(milestone)) {
        yield* failWith(`milestone "${milestoneId}" not found in ${roadmapId}`)
        return
      }

      const task = findTask(milestone, taskId)
      if (Predicate.isNullish(task)) {
        yield* failWith(`task "${taskId}" not found under ${roadmapId}/${milestoneId}`)
        return
      }

      yield* Console.log(`task_id:              ${task.id}`)
      yield* Console.log(`milestone_id:         ${milestone.id}`)
      yield* Console.log(`roadmap_id:           ${progress.roadmap_id}`)
      yield* Console.log(`title:                ${task.title}`)
      yield* Console.log(`status:               ${task.status}`)
      yield* Console.log(`workflow_identifiers: ${formatList(task.workflow_identifiers)}`)
      yield* Console.log(`prs:                  ${formatList(task.prs)}`)
      yield* Console.log(`notes:                ${task.notes ?? '(none)'}`)
    }),
).pipe(Command.withDescription('Show detailed status of one task'))
