import { Array, Console, Effect, Predicate } from 'effect'
import { Command } from 'effect/unstable/cli'

import { rootCommand } from '#@/cli/root.ts'
import { listRoadmaps } from '#@/lib/progress.ts'
import type { Milestone } from '#@/schema/progress.ts'

const failWith = (message: string) =>
  Effect.gen(function* () {
    yield* Console.error(`error: ${message}`)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
    return null
  })

const countCompleted = (milestones: readonly Milestone[]): number =>
  milestones.filter((m) => m.status === 'completed').length

export const lsCommand = Command.make('ls', {}, () =>
  Effect.gen(function* () {
    const { dir } = yield* rootCommand
    const roadmaps = yield* listRoadmaps(dir).pipe(
      Effect.catchTags({
        ProgressDirNotFoundError: (error) => failWith(`${error.dir} not found`),
        ProgressReadError: (error) => failWith(`failed to read ${error.path}: ${error.message}`),
        ProgressValidationError: (error) => failWith(`invalid roadmap progress (${error.message})`),
      }),
    )

    if (Predicate.isNullish(roadmaps)) {
      return
    }

    if (Array.isReadonlyArrayEmpty(roadmaps)) {
      yield* Console.log(`(no roadmaps found under ${dir})`)
      return
    }

    for (const r of roadmaps) {
      const completed = countCompleted(r.milestones)
      yield* Console.log(
        `- ${r.roadmap_id} (${r.status}) ${r.title} \u2014 milestones: ${completed}/${r.milestones.length}`,
      )
    }
  }),
).pipe(Command.withDescription('List roadmaps under <dir>'))
