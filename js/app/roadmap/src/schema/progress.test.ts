import { Schema } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { Milestone, MilestoneStatus, RoadmapProgress, RoadmapStatus } from './progress.ts'

const decodeMilestoneStatus = Schema.decodeUnknownSync(MilestoneStatus)
const decodeRoadmapStatus = Schema.decodeUnknownSync(RoadmapStatus)
const decodeMilestone = Schema.decodeUnknownSync(Milestone)
const decodeRoadmapProgress = Schema.decodeUnknownSync(RoadmapProgress)

const VALID_MILESTONE = {
  depends_on: ['ms-00-foo'],
  id: 'ms-01-bar',
  notes: null,
  prs: ['https://github.com/x/y/pull/1'],
  status: 'planned',
  title: 'Bar',
  workflow_identifiers: ['wf-2026-05-21-bar'],
} as const

const VALID_ROADMAP = {
  created_at: '2026-05-15T16:15:13.160Z',
  milestones: [VALID_MILESTONE],
  prs: [],
  roadmap_id: 'roadmap-cli',
  status: 'active',
  title: 'Roadmap management CLI',
  updated_at: '2026-05-15T16:15:13.160Z',
} as const

describe('MilestoneStatus', () => {
  test('accepts planned', () => {
    expect(decodeMilestoneStatus('planned')).toBe('planned')
  })

  test('accepts active', () => {
    expect(decodeMilestoneStatus('active')).toBe('active')
  })

  test('accepts completed', () => {
    expect(decodeMilestoneStatus('completed')).toBe('completed')
  })

  test('accepts blocked', () => {
    expect(decodeMilestoneStatus('blocked')).toBe('blocked')
  })

  test('accepts cancelled', () => {
    expect(decodeMilestoneStatus('cancelled')).toBe('cancelled')
  })

  test('rejects unknown status string', () => {
    expect(() => decodeMilestoneStatus('archived')).toThrow()
  })
})

describe('RoadmapStatus', () => {
  test('accepts planned', () => {
    expect(decodeRoadmapStatus('planned')).toBe('planned')
  })

  test('accepts active', () => {
    expect(decodeRoadmapStatus('active')).toBe('active')
  })

  test('accepts completed', () => {
    expect(decodeRoadmapStatus('completed')).toBe('completed')
  })

  test('rejects milestone-only status blocked', () => {
    expect(() => decodeRoadmapStatus('blocked')).toThrow()
  })

  test('rejects milestone-only status cancelled', () => {
    expect(() => decodeRoadmapStatus('cancelled')).toThrow()
  })
})

describe('Milestone id - KebabCase', () => {
  test('accepts simple kebab segment', () => {
    const result = decodeMilestone({ ...VALID_MILESTONE, id: 'foo' })
    expect(result.id).toBe('foo')
  })

  test('accepts multi-segment kebab', () => {
    const result = decodeMilestone({ ...VALID_MILESTONE, id: 'ms-01-foundation' })
    expect(result.id).toBe('ms-01-foundation')
  })

  test('accepts digits inside segments', () => {
    const result = decodeMilestone({ ...VALID_MILESTONE, id: 'ms-12-closest-intersection' })
    expect(result.id).toBe('ms-12-closest-intersection')
  })

  test('rejects empty string id', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, id: '' })).toThrow()
  })

  test('rejects CamelCase id', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, id: 'FooBar' })).toThrow()
  })

  test('rejects snake_case id', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, id: 'foo_bar' })).toThrow()
  })

  test('rejects id with whitespace', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, id: 'foo bar' })).toThrow()
  })
})

describe('Milestone', () => {
  test('decodes a complete milestone', () => {
    expect(decodeMilestone(VALID_MILESTONE)).toStrictEqual(VALID_MILESTONE)
  })

  test('decodes milestone with notes string', () => {
    const input = { ...VALID_MILESTONE, notes: 'follow up next sprint' }
    expect(decodeMilestone(input).notes).toBe('follow up next sprint')
  })

  test('rejects missing id field', () => {
    const { id: _id, ...rest } = VALID_MILESTONE
    expect(() => decodeMilestone(rest)).toThrow()
  })

  test('rejects missing prs field', () => {
    const { prs: _prs, ...rest } = VALID_MILESTONE
    expect(() => decodeMilestone(rest)).toThrow()
  })

  test('rejects empty title', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, title: '' })).toThrow()
  })

  test('rejects depends_on element that is not kebab-case', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, depends_on: ['NotKebab'] })).toThrow()
  })

  test('rejects empty workflow_identifier element', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, workflow_identifiers: [''] })).toThrow()
  })
})

describe('RoadmapProgress', () => {
  test('decodes a complete roadmap progress', () => {
    const result = decodeRoadmapProgress(VALID_ROADMAP)
    expect(result.roadmap_id).toBe('roadmap-cli')
    expect(result.milestones).toStrictEqual([VALID_MILESTONE])
    expect(result.prs).toStrictEqual([])
  })

  test('rejects missing prs field', () => {
    const { prs: _prs, ...rest } = VALID_ROADMAP
    expect(() => decodeRoadmapProgress(rest)).toThrow()
  })

  test('rejects roadmap-level blocked status', () => {
    expect(() => decodeRoadmapProgress({ ...VALID_ROADMAP, status: 'blocked' })).toThrow()
  })

  test('rejects non-ISO created_at', () => {
    expect(() => decodeRoadmapProgress({ ...VALID_ROADMAP, created_at: 'yesterday' })).toThrow()
  })

  test('rejects roadmap_id that is not kebab-case', () => {
    expect(() => decodeRoadmapProgress({ ...VALID_ROADMAP, roadmap_id: 'NotKebab' })).toThrow()
  })
})
