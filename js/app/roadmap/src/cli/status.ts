import { Array, Console, DateTime, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import { resolveDirOrFail, rootCommand } from '#@/cli/root.ts'
import type { Milestone } from '#@/feature/schema/current.ts'
import { readProgressFile } from '#@/lib/progress.ts'

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

const formatList = (items: readonly string[]): string =>
  Array.isReadonlyArrayEmpty(items) ? '(none)' : items.join(', ')

export const statusCommand = Command.make(
  'status',
  {
    roadmapId: Argument.string('roadmap-id'),
  },
  ({ roadmapId }) =>
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

      const completed = countCompleted(progress.milestones)
      yield* Console.log(`roadmap_id: ${progress.roadmap_id}`)
      yield* Console.log(`title:      ${progress.title}`)
      yield* Console.log(`status:     ${progress.status}`)
      yield* Console.log(`created_at: ${DateTime.formatIso(progress.created_at)}`)
      yield* Console.log(`updated_at: ${DateTime.formatIso(progress.updated_at)}`)
      yield* Console.log(`prs:        ${formatList(progress.prs)}`)
      yield* Console.log('')
      yield* Console.log(`milestones (${completed}/${progress.milestones.length} completed):`)
      if (Array.isReadonlyArrayEmpty(progress.milestones)) {
        yield* Console.log('  (none)')
        return
      }
      for (const m of progress.milestones) {
        yield* Console.log(`  - ${m.id} (${m.status}) ${m.title}`)
      }
    }),
).pipe(Command.withDescription('Show detailed status of one roadmap'))
