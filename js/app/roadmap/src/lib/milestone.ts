import { join } from 'node:path'

import { Data, DateTime, Effect, FileSystem, Schema } from 'effect'

import { ProgressValidationError, readProgressFile, writeProgressFile } from '#@/lib/progress.ts';
import type { ProgressFileNotFoundError, ProgressReadError, ProgressWriteError } from '#@/lib/progress.ts';
import { Milestone } from '#@/schema/progress.ts'

import MILESTONE_TEMPLATE from './milestone-template.md'

export class MilestoneAlreadyExistsError extends Data.TaggedError('MilestoneAlreadyExistsError')<{
  readonly roadmapId: string
  readonly milestoneId: string
}> {}

export class MilestoneFileExistsError extends Data.TaggedError('MilestoneFileExistsError')<{
  readonly path: string
}> {}

export class MilestoneWriteError extends Data.TaggedError('MilestoneWriteError')<{
  readonly path: string
  readonly message: string
}> {}

const decodeMilestone = Schema.decodeUnknownEffect(Milestone)

const milestonePath = (dir: string, roadmapId: string, milestoneId: string): string =>
  join(dir, roadmapId, 'milestones', `${milestoneId}.md`)

const renderMilestoneTemplate = (input: {
  readonly milestoneId: string
  readonly roadmapId: string
  readonly title: string
}): string =>
  MILESTONE_TEMPLATE.replaceAll('{{milestone_title}}', input.title)
    .replaceAll('{{milestone_id}}', input.milestoneId)
    .replaceAll('{{roadmap_id}}', input.roadmapId)

export interface AddMilestoneInput {
  readonly roadmapId: string
  readonly milestoneId: string
  readonly title: string
  readonly dir: string
  readonly now: DateTime.Utc
}

export interface AddMilestoneResult {
  readonly progressPath: string
  readonly milestonePath: string
}

export const addMilestone = (
  input: AddMilestoneInput,
): Effect.Effect<
  AddMilestoneResult,
  | MilestoneAlreadyExistsError
  | MilestoneFileExistsError
  | MilestoneWriteError
  | ProgressFileNotFoundError
  | ProgressReadError
  | ProgressValidationError
  | ProgressWriteError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })

    if (progress.milestones.some((m) => m.id === input.milestoneId)) {
      return yield* new MilestoneAlreadyExistsError({
        milestoneId: input.milestoneId,
        roadmapId: input.roadmapId,
      })
    }

    const targetPath = milestonePath(input.dir, input.roadmapId, input.milestoneId)

    const toMilestoneWriteError = (error: unknown): MilestoneWriteError =>
      new MilestoneWriteError({
        message: error instanceof Error ? error.message : String(error),
        path: targetPath,
      })

    if (yield* fs.exists(targetPath).pipe(Effect.mapError(toMilestoneWriteError))) {
      return yield* new MilestoneFileExistsError({ path: targetPath })
    }

    const milestone = yield* decodeMilestone({
      depends_on: [],
      id: input.milestoneId,
      notes: null,
      status: 'planned',
      title: input.title,
      workflow_identifiers: [],
    }).pipe(Effect.mapError((error) => new ProgressValidationError({ message: String(error) })))

    yield* fs
      .makeDirectory(join(input.dir, input.roadmapId, 'milestones'), { recursive: true })
      .pipe(Effect.mapError(toMilestoneWriteError))
    yield* fs.writeFileString(targetPath, renderMilestoneTemplate(input)).pipe(Effect.mapError(toMilestoneWriteError))

    const progressResult = yield* writeProgressFile({
      data: {
        ...progress,
        milestones: [...progress.milestones, milestone],
        updated_at: input.now,
      },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { milestonePath: targetPath, progressPath: progressResult.path }
  })
