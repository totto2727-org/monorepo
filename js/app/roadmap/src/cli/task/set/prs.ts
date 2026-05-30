import { Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import { updateTaskPrs } from '#@/lib/task.ts'

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
      const { dir } = yield* resolveDirOrFail(relativeDir)
      const now = yield* DateTime.now
      const result = yield* updateTaskPrs({
        append,
        dir,
        milestoneId,
        now,
        prs,
        roadmapId,
        taskId,
      })

      if (Predicate.isNotNullish(result)) {
        const action = append ? 'Appended' : 'Set'
        yield* Console.log(`${action} ${roadmapId}/${milestoneId}/${taskId} PRs: [${prs.join(', ')}]`)
      }
    }),
).pipe(Command.withDescription("Set a task's linked PRs"))
