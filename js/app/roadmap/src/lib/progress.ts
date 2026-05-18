import { dirname, join } from 'node:path'

import { Data, DateTime, Effect, FileSystem, Schema } from 'effect'
import { dump as dumpYaml } from 'js-yaml'

import { RoadmapProgress } from '#@/schema/progress.ts'

export class ProgressFileExistsError extends Data.TaggedError('ProgressFileExistsError')<{
  readonly path: string
}> {}

export class ProgressWriteError extends Data.TaggedError('ProgressWriteError')<{
  readonly path: string
  readonly message: string
}> {}

export class ProgressValidationError extends Data.TaggedError('ProgressValidationError')<{
  readonly message: string
}> {}

const decodeUnknown = Schema.decodeUnknownEffect(RoadmapProgress)

const HEADER_COMMENT = `# Roadmap progress tracking yaml managed by the \`roadmap\` CLI.
# Schema reference: plugins/dev-workflow/skills/share-artifacts/references/roadmap-progress-yaml.md
`

const renderYaml = (data: RoadmapProgress): string => {
  const body = dumpYaml(
    {
      roadmap_id: data.roadmap_id,
      title: data.title,
      status: data.status,
      created_at: DateTime.formatIso(data.created_at),
      updated_at: DateTime.formatIso(data.updated_at),
      milestones: data.milestones,
    },
    { lineWidth: -1, noRefs: true },
  )
  return `${HEADER_COMMENT}\n${body}`
}

export interface InitInput {
  readonly roadmapId: string
  readonly title: string
  readonly dir: string
  readonly now: DateTime.Utc
}

export interface InitResult {
  readonly path: string
}

export const initProgressFile = (
  input: InitInput,
): Effect.Effect<
  InitResult,
  ProgressFileExistsError | ProgressValidationError | ProgressWriteError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const targetDir = join(input.dir, input.roadmapId)
    const targetPath = join(targetDir, 'progress.yaml')

    const timestamp = DateTime.formatIso(input.now)
    const draft = {
      roadmap_id: input.roadmapId,
      title: input.title,
      status: 'planned',
      created_at: timestamp,
      updated_at: timestamp,
      milestones: [],
    }

    const validated = yield* decodeUnknown(draft).pipe(
      Effect.mapError((error) => new ProgressValidationError({ message: String(error) })),
    )

    const toWriteError = (error: unknown): ProgressWriteError =>
      new ProgressWriteError({
        message: error instanceof Error ? error.message : String(error),
        path: targetPath,
      })

    if (yield* fs.exists(targetPath).pipe(Effect.mapError(toWriteError))) {
      return yield* new ProgressFileExistsError({ path: targetPath })
    }

    yield* fs.makeDirectory(dirname(targetPath), { recursive: true }).pipe(Effect.mapError(toWriteError))
    yield* fs.writeFileString(targetPath, renderYaml(validated)).pipe(Effect.mapError(toWriteError))

    return { path: targetPath }
  })
