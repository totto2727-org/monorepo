import { Console, DateTime, Effect, Option, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { addTask } from '#@/lib/task.ts'

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
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const resolvedTitle = Option.getOrElse(title, () => taskId)
      const now = yield* DateTime.now
      const result = yield* addTask({
        dir,
        milestoneId,
        now,
        roadmapId,
        taskId,
        title: resolvedTitle,
      })

      if (Predicate.isNotNullish(result)) {
        yield* Console.log(`Added task ${roadmapId}/${milestoneId}/${taskId}`)
        yield* Console.log(`Updated ${result.progressPath}`)
      }
    }),
).pipe(Command.withDescription('Add a task under a milestone in docs/roadmap/<roadmap-id>/progress.yaml'))
