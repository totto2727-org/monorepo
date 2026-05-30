// oxlint-disable max-classes-per-file -- TaggedError subclasses are grouped by domain
import { dirname, join } from 'node:path'

import { Data, DateTime, Effect, FileSystem, Predicate, Schema } from 'effect'
import { dump as dumpYaml, load as loadYaml } from 'js-yaml'

import type { RoadmapStatus } from '#@/feature/schema/current.ts'
import { RoadmapProgress, SCHEMA_VERSION } from '#@/feature/schema/current.ts'
import { migrate } from '#@/feature/schema/migrate.ts'
import type { Worktree } from '#@/lib/git.ts'

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- draft is a partially-typed literal
const decodeRoadmapProgress = Schema.decodeUnknownEffect(RoadmapProgress)

export class ProgressFileExistsError extends Data.TaggedError('ProgressFileExistsError')<{
  readonly path: string
}> {}

export class ProgressFileNotFoundError extends Data.TaggedError('ProgressFileNotFoundError')<{
  readonly path: string
}> {}

export class ProgressReadError extends Data.TaggedError('ProgressReadError')<{
  readonly path: string
  readonly message: string
}> {}

export class ProgressWriteError extends Data.TaggedError('ProgressWriteError')<{
  readonly path: string
  readonly message: string
}> {}

export class ProgressValidationError extends Data.TaggedError('ProgressValidationError')<{
  readonly message: string
}> {}

const HEADER_COMMENT = `# Roadmap progress tracking yaml managed by the \`roadmap\` CLI.
# Schema reference: plugins/dev-workflow/skills/share-artifacts/references/roadmap-progress-yaml.md
`

export const progressFilePath = (dir: string, roadmapId: string): string => join(dir, roadmapId, 'progress.yaml')

export const mergePrs = (
  existing: readonly string[],
  incoming: readonly string[],
  append: boolean,
): readonly string[] => {
  if (!append) {
    return [...incoming]
  }
  const seen = new Set<string>(existing)
  const merged: string[] = [...existing]
  for (const pr of incoming) {
    if (seen.has(pr)) {
      continue
    }
    seen.add(pr)
    merged.push(pr)
  }
  return merged
}

export const renderProgressYaml = (data: RoadmapProgress): string => {
  const body = dumpYaml(
    {
      created_at: DateTime.formatIso(data.created_at),
      milestones: data.milestones,
      prs: data.prs,
      roadmap_id: data.roadmap_id,
      status: data.status,
      title: data.title,
      updated_at: DateTime.formatIso(data.updated_at),
      version: SCHEMA_VERSION,
    },
    { lineWidth: -1, noRefs: true, sortKeys: true },
  )
  return `${HEADER_COMMENT}\n${body}`
}

export interface ReadInput {
  readonly dir: string
  readonly roadmapId: string
}

export const readProgressFile = (
  input: ReadInput,
): Effect.Effect<
  RoadmapProgress,
  ProgressFileNotFoundError | ProgressReadError | ProgressValidationError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = progressFilePath(input.dir, input.roadmapId)

    const toReadError = (error: unknown): ProgressReadError =>
      new ProgressReadError({
        message: error instanceof Error ? error.message : String(error),
        path,
      })

    if (!(yield* fs.exists(path).pipe(Effect.mapError(toReadError)))) {
      return yield* new ProgressFileNotFoundError({ path })
    }

    const raw = yield* fs.readFileString(path).pipe(Effect.mapError(toReadError))

    const parsed = yield* Effect.try({
      catch: (error) =>
        new ProgressValidationError({
          message: `failed to parse yaml at ${path}: ${error instanceof Error ? error.message : String(error)}`,
        }),
      try: () => loadYaml(raw),
    })

    return yield* migrate(parsed).pipe(
      Effect.catchTags({
        SchemaDecodeError: (error) =>
          Effect.fail(new ProgressValidationError({ message: `${path} (v${error.version}): ${error.message}` })),
        SchemaVersionError: (error) =>
          Effect.fail(
            new ProgressValidationError({
              message: `${path}: unsupported schema version (${String(error.version)})`,
            }),
          ),
      }),
    )
  })

export interface WriteInput {
  readonly dir: string
  readonly roadmapId: string
  readonly data: RoadmapProgress
}

export interface WriteResult {
  readonly path: string
}

export const writeProgressFile = (
  input: WriteInput,
): Effect.Effect<WriteResult, ProgressWriteError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = progressFilePath(input.dir, input.roadmapId)

    const toWriteError = (error: unknown): ProgressWriteError =>
      new ProgressWriteError({
        message: error instanceof Error ? error.message : String(error),
        path,
      })

    yield* fs.makeDirectory(dirname(path), { recursive: true }).pipe(Effect.mapError(toWriteError))
    yield* fs.writeFileString(path, renderProgressYaml(input.data)).pipe(Effect.mapError(toWriteError))

    return { path }
  })

export interface InitInput {
  readonly roadmapId: string
  readonly title: string
  readonly dir: string
  readonly now: DateTime.Utc
}

export interface InitResult {
  readonly path: string
}

export class ProgressDirNotFoundError extends Data.TaggedError('ProgressDirNotFoundError')<{
  readonly dir: string
}> {}

export const listRoadmaps = (
  dir: string,
): Effect.Effect<
  readonly RoadmapProgress[],
  ProgressDirNotFoundError | ProgressReadError | ProgressValidationError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem

    const toReadError =
      (path: string) =>
      (error: unknown): ProgressReadError =>
        new ProgressReadError({
          message: error instanceof Error ? error.message : String(error),
          path,
        })

    if (!(yield* fs.exists(dir).pipe(Effect.mapError(toReadError(dir))))) {
      return yield* new ProgressDirNotFoundError({ dir })
    }

    const entries = yield* fs.readDirectory(dir).pipe(Effect.mapError(toReadError(dir)))

    // oxlint-disable-next-line unicorn/no-array-method-this-argument -- Effect.forEach, not Array.forEach
    const results = yield* Effect.forEach(entries, (entry) =>
      Effect.gen(function* () {
        if (entry.startsWith('.')) {
          return null
        }
        const entryPath = join(dir, entry)
        const info = yield* fs.stat(entryPath).pipe(Effect.mapError(toReadError(entryPath)))
        if (info.type !== 'Directory') {
          return null
        }
        const progressPath = progressFilePath(dir, entry)
        if (!(yield* fs.exists(progressPath).pipe(Effect.mapError(toReadError(progressPath))))) {
          return null
        }
        return yield* readProgressFile({ dir, roadmapId: entry }).pipe(
          Effect.catchTag('ProgressFileNotFoundError', () => Effect.succeed(null)),
          Effect.catchTag('ProgressValidationError', (e) =>
            Effect.logWarning(`Skipping invalid progress file: ${e.message}`).pipe(Effect.as(null)),
          ),
          Effect.catchTag('ProgressReadError', (e) =>
            Effect.logWarning(`Skipping unreadable progress file (${e.path}): ${e.message}`).pipe(Effect.as(null)),
          ),
        )
      }),
    )

    return results.filter(Predicate.isNotNullish).toSorted((a, b) => a.roadmap_id.localeCompare(b.roadmap_id))
  })

export interface WorktreeRoadmaps {
  readonly worktree: Worktree
  readonly roadmaps: readonly RoadmapProgress[]
}

export const listRoadmapsAcrossWorktrees = (
  worktrees: readonly Worktree[],
  relativeDir: string,
): Effect.Effect<readonly WorktreeRoadmaps[], ProgressReadError | ProgressValidationError, FileSystem.FileSystem> =>
  // oxlint-disable-next-line unicorn/no-array-method-this-argument -- Effect.forEach, not Array.forEach
  Effect.forEach(worktrees, (worktree) =>
    listRoadmaps(join(worktree.path, relativeDir)).pipe(
      Effect.catchTag('ProgressDirNotFoundError', () => Effect.succeed([] as readonly RoadmapProgress[])),
      Effect.map((roadmaps) => ({ roadmaps, worktree })),
    ),
  )

export interface UpdateRoadmapStatusInput {
  readonly dir: string
  readonly roadmapId: string
  readonly status: RoadmapStatus
  readonly now: DateTime.Utc
}

export const updateRoadmapStatus = (
  input: UpdateRoadmapStatusInput,
): Effect.Effect<
  WriteResult,
  ProgressFileNotFoundError | ProgressReadError | ProgressValidationError | ProgressWriteError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })
    return yield* writeProgressFile({
      data: { ...progress, status: input.status, updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })
  })

export interface UpdateRoadmapPrsInput {
  readonly dir: string
  readonly roadmapId: string
  readonly prs: readonly string[]
  readonly append: boolean
  readonly now: DateTime.Utc
}

export const updateRoadmapPrs = (
  input: UpdateRoadmapPrsInput,
): Effect.Effect<
  WriteResult,
  ProgressFileNotFoundError | ProgressReadError | ProgressValidationError | ProgressWriteError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const progress = yield* readProgressFile({ dir: input.dir, roadmapId: input.roadmapId })
    return yield* writeProgressFile({
      data: { ...progress, prs: mergePrs(progress.prs, input.prs, input.append), updated_at: input.now },
      dir: input.dir,
      roadmapId: input.roadmapId,
    })
  })

export const initProgressFile = (
  input: InitInput,
): Effect.Effect<
  InitResult,
  ProgressFileExistsError | ProgressValidationError | ProgressWriteError,
  FileSystem.FileSystem
> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = progressFilePath(input.dir, input.roadmapId)

    const timestamp = DateTime.formatIso(input.now)
    const draft = {
      created_at: timestamp,
      milestones: [],
      prs: [],
      roadmap_id: input.roadmapId,
      status: 'planned',
      title: input.title,
      updated_at: timestamp,
      version: SCHEMA_VERSION,
    }

    const validated = yield* decodeRoadmapProgress(draft).pipe(
      Effect.mapError((error) => new ProgressValidationError({ message: String(error) })),
    )

    const toWriteError = (error: unknown): ProgressWriteError =>
      new ProgressWriteError({
        message: error instanceof Error ? error.message : String(error),
        path,
      })

    if (yield* fs.exists(path).pipe(Effect.mapError(toWriteError))) {
      return yield* new ProgressFileExistsError({ path })
    }

    const result = yield* writeProgressFile({
      data: validated,
      dir: input.dir,
      roadmapId: input.roadmapId,
    })

    return { path: result.path }
  })
