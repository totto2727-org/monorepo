import { kebabCase } from '@totto2727/fp/case'
import { Option, Schema, SchemaAST, SchemaIssue, String } from 'effect'

export const MilestoneStatus = Schema.Literals(['planned', 'active', 'completed', 'blocked', 'cancelled'])
export type MilestoneStatus = typeof MilestoneStatus.Type

export const RoadmapStatus = Schema.Literals(['planned', 'active', 'completed'])
export type RoadmapStatus = typeof RoadmapStatus.Type

const isKebabCase = new SchemaAST.Filter<string>((input) =>
  String.isNonEmpty(input) && kebabCase(input) === input
    ? undefined
    : new SchemaIssue.InvalidValue(Option.some(input), { message: 'must be kebab-case' }),
)

const KebabCase = Schema.String.pipe(Schema.check(isKebabCase))

export const Milestone = Schema.Struct({
  depends_on: Schema.Array(KebabCase),
  id: KebabCase,
  notes: Schema.NullOr(Schema.String),
  prs: Schema.Array(Schema.String),
  status: MilestoneStatus,
  title: Schema.NonEmptyString,
  workflow_identifiers: Schema.Array(Schema.NonEmptyString),
})
export type Milestone = typeof Milestone.Type

export const RoadmapProgress = Schema.Struct({
  created_at: Schema.DateTimeUtcFromString,
  milestones: Schema.Array(Milestone),
  prs: Schema.Array(Schema.String),
  roadmap_id: KebabCase,
  status: RoadmapStatus,
  title: Schema.NonEmptyString,
  updated_at: Schema.DateTimeUtcFromString,
})
export type RoadmapProgress = typeof RoadmapProgress.Type
