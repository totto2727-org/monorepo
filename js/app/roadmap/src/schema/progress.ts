import { kebabCase } from 'change-case'
import { Option, Schema, SchemaAST, SchemaIssue } from 'effect'

export const MilestoneStatus = Schema.Literals(['planned', 'active', 'completed', 'blocked', 'cancelled'])
export type MilestoneStatus = typeof MilestoneStatus.Type

export const RoadmapStatus = Schema.Literals(['planned', 'active', 'completed'])
export type RoadmapStatus = typeof RoadmapStatus.Type

const isKebabCase = new SchemaAST.Filter<string>(
  (input) =>
    input.length > 0 && kebabCase(input) === input
      ? undefined
      : new SchemaIssue.InvalidValue(Option.some(input), { message: 'must be kebab-case' }),
)

const KebabCase = Schema.String.pipe(Schema.check(isKebabCase))

export const Milestone = Schema.Struct({
  id: KebabCase,
  title: Schema.NonEmptyString,
  status: MilestoneStatus,
  depends_on: Schema.Array(KebabCase),
  workflow_identifiers: Schema.Array(Schema.NonEmptyString),
  notes: Schema.NullOr(Schema.String),
})
export type Milestone = typeof Milestone.Type

export const RoadmapProgress = Schema.Struct({
  roadmap_id: KebabCase,
  title: Schema.NonEmptyString,
  status: RoadmapStatus,
  created_at: Schema.DateTimeUtcFromString,
  updated_at: Schema.DateTimeUtcFromString,
  milestones: Schema.Array(Milestone),
})
export type RoadmapProgress = typeof RoadmapProgress.Type
