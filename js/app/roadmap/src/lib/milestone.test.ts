import { Schema } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { Milestone, RoadmapProgress } from '#@/schema/progress.ts'

import { findMilestone, milestonePath, renderMilestoneTemplate } from './milestone.ts'

const buildMilestone = (overrides: Partial<typeof Milestone.Encoded> = {}) =>
  Schema.decodeUnknownSync(Milestone)({
    depends_on: [],
    id: 'ms-01-foo',
    notes: null,
    prs: [],
    status: 'planned',
    title: 'Foo',
    workflow_identifiers: [],
    ...overrides,
  })

const buildRoadmap = (milestones: readonly (typeof Milestone.Type)[]) =>
  Schema.decodeUnknownSync(RoadmapProgress)({
    created_at: '2026-05-15T16:15:13.160Z',
    milestones: milestones.map((m) => Schema.encodeSync(Milestone)(m)),
    prs: [],
    roadmap_id: 'alpha',
    status: 'planned',
    title: 'Alpha',
    updated_at: '2026-05-15T16:15:13.160Z',
  })

describe('milestonePath', () => {
  test('joins dir, roadmap id, milestones segment and <id>.md filename', () => {
    expect(milestonePath('docs/roadmap', 'alpha', 'ms-01-foo')).toBe('docs/roadmap/alpha/milestones/ms-01-foo.md')
  })

  test('normalizes trailing slash on dir', () => {
    expect(milestonePath('docs/roadmap/', 'alpha', 'ms-01-foo')).toBe('docs/roadmap/alpha/milestones/ms-01-foo.md')
  })

  test('handles absolute dir', () => {
    expect(milestonePath('/abs/roadmap', 'alpha', 'ms-01-foo')).toBe('/abs/roadmap/alpha/milestones/ms-01-foo.md')
  })
})

describe('renderMilestoneTemplate', () => {
  test('replaces all three placeholders in the bundled template', () => {
    const result = renderMilestoneTemplate({ milestoneId: 'ms-01-foo', roadmapId: 'alpha', title: 'Foo Title' })
    expect(result).toContain("milestone_id: 'ms-01-foo'")
    expect(result).toContain("roadmap_id: 'alpha'")
    expect(result).toContain('# Milestone: Foo Title')
  })

  test('does not leave any milestone_id placeholder unreplaced', () => {
    const result = renderMilestoneTemplate({ milestoneId: 'ms-01-foo', roadmapId: 'alpha', title: 'Foo' })
    expect(result.includes('{{milestone_id}}')).toBe(false)
  })

  test('does not leave any roadmap_id placeholder unreplaced', () => {
    const result = renderMilestoneTemplate({ milestoneId: 'ms-01-foo', roadmapId: 'alpha', title: 'Foo' })
    expect(result.includes('{{roadmap_id}}')).toBe(false)
  })

  test('does not leave any milestone_title placeholder unreplaced', () => {
    const result = renderMilestoneTemplate({ milestoneId: 'ms-01-foo', roadmapId: 'alpha', title: 'Foo' })
    expect(result.includes('{{milestone_title}}')).toBe(false)
  })

  test('substitutes each placeholder occurrence (all instances replaced, not just first)', () => {
    const result = renderMilestoneTemplate({ milestoneId: 'X-id', roadmapId: 'Y-id', title: 'T' })
    expect(result.includes('{{milestone_id}}')).toBe(false)
    expect(result.includes('{{roadmap_id}}')).toBe(false)
    expect(result.includes('{{milestone_title}}')).toBe(false)
  })
})

describe('findMilestone', () => {
  test('returns the milestone whose id matches', () => {
    const target = buildMilestone({ id: 'ms-02-bar', title: 'Bar' })
    const progress = buildRoadmap([buildMilestone({ id: 'ms-01-foo' }), target, buildMilestone({ id: 'ms-03-baz' })])
    expect(findMilestone(progress, 'ms-02-bar')).toStrictEqual(target)
  })

  test('returns undefined when id is not present', () => {
    const progress = buildRoadmap([buildMilestone({ id: 'ms-01-foo' })])
    expect(findMilestone(progress, 'ms-99-missing')).toBeUndefined()
  })

  test('returns undefined when milestones array is empty', () => {
    const progress = buildRoadmap([])
    expect(findMilestone(progress, 'ms-01-foo')).toBeUndefined()
  })

  test('returns the first match when multiple milestones somehow share an id', () => {
    const first = buildMilestone({ id: 'ms-dup', title: 'First' })
    const second = buildMilestone({ id: 'ms-dup', title: 'Second' })
    const progress = buildRoadmap([first, second])
    expect(findMilestone(progress, 'ms-dup')).toStrictEqual(first)
  })
})
