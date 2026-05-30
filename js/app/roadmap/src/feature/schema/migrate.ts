// oxlint-disable max-classes-per-file -- TaggedError subclasses are grouped by domain
import { Data, Effect, Predicate, Schema } from 'effect'

import * as V1 from './v1.ts'
import * as V2 from './v2.ts'

export class SchemaVersionError extends Data.TaggedError('SchemaVersionError')<{
  readonly version: unknown
}> {}

export class SchemaDecodeError extends Data.TaggedError('SchemaDecodeError')<{
  readonly version: number
  readonly message: string
}> {}

const LATEST_VERSION = V2.SCHEMA_VERSION

const detectVersion = (raw: unknown): number | undefined => {
  if (!Predicate.isObject(raw)) {
    return undefined
  }
  if (!('version' in raw)) {
    return 1
  }
  const candidate: unknown = raw.version
  return Predicate.isNumber(candidate) ? candidate : undefined
}

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is parsed YAML (unknown)
const decodeV1 = Schema.decodeUnknownEffect(V1.RoadmapProgress)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is parsed YAML (unknown)
const decodeV2 = Schema.decodeUnknownEffect(V2.RoadmapProgress)

const toV1DecodeError = (error: unknown): SchemaDecodeError =>
  new SchemaDecodeError({ message: String(error), version: 1 })

const toV2DecodeError = (error: unknown): SchemaDecodeError =>
  new SchemaDecodeError({ message: String(error), version: 2 })

const migrateV1ToV2 = (v1: V1.RoadmapProgress): V2.RoadmapProgress => ({
  created_at: v1.created_at,
  milestones: v1.milestones.map(
    (m): V2.Milestone => ({
      depends_on: m.depends_on,
      id: m.id,
      notes: m.notes,
      prs: m.prs,
      status: m.status,
      tasks: [],
      title: m.title,
      workflow_identifiers: m.workflow_identifiers,
    }),
  ),
  prs: v1.prs,
  roadmap_id: v1.roadmap_id,
  status: v1.status,
  title: v1.title,
  updated_at: v1.updated_at,
  version: V2.SCHEMA_VERSION,
})

export const migrate = (raw: unknown): Effect.Effect<V2.RoadmapProgress, SchemaVersionError | SchemaDecodeError> =>
  Effect.gen(function* () {
    const version = detectVersion(raw)
    if (Predicate.isNullish(version) || version > LATEST_VERSION) {
      return yield* Effect.fail(new SchemaVersionError({ version }))
    }
    switch (version) {
      case 1: {
        const v1 = yield* decodeV1(raw).pipe(Effect.mapError(toV1DecodeError))
        return migrateV1ToV2(v1)
      }
      case 2: {
        return yield* decodeV2(raw).pipe(Effect.mapError(toV2DecodeError))
      }
      default: {
        return yield* Effect.fail(new SchemaVersionError({ version }))
      }
    }
  })
