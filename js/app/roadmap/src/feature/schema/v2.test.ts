import { Schema } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { Milestone, MilestoneStatus, RoadmapProgress, RoadmapStatus, SCHEMA_VERSION, Task } from './v2.ts'

const decodeMilestoneStatus = Schema.decodeUnknownSync(MilestoneStatus)
const decodeRoadmapStatus = Schema.decodeUnknownSync(RoadmapStatus)
const decodeTask = Schema.decodeUnknownSync(Task)
const decodeMilestone = Schema.decodeUnknownSync(Milestone)
const decodeRoadmapProgress = Schema.decodeUnknownSync(RoadmapProgress)

const VALID_TASK = {
  id: 't-01-bar',
  notes: null,
  prs: [],
  status: 'planned',
  title: 'Bar',
  workflow_identifiers: [],
} as const

const VALID_MILESTONE = {
  depends_on: ['ms-00-foo'],
  id: 'ms-01-bar',
  notes: null,
  prs: ['https://github.com/x/y/pull/1'],
  status: 'planned',
  tasks: [VALID_TASK],
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
  version: 2,
} as const

describe('SCHEMA_VERSION', () => {
  test('is the integer literal 2', () => {
    expect(SCHEMA_VERSION).toBe(2)
  })
})

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

describe('Task', () => {
  test('accepts a minimal task', () => {
    const result = decodeTask(VALID_TASK)
    expect(result.id).toBe('t-01-bar')
    expect(result.status).toBe('planned')
  })

  test('rejects non-kebab id', () => {
    expect(() => decodeTask({ ...VALID_TASK, id: 'TaskOne' })).toThrow()
  })

  test('rejects empty title', () => {
    expect(() => decodeTask({ ...VALID_TASK, title: '' })).toThrow()
  })

  test('rejects unknown status', () => {
    expect(() => decodeTask({ ...VALID_TASK, status: 'shipped' })).toThrow()
  })
})

describe('Milestone', () => {
  test('accepts a milestone with an empty tasks array', () => {
    const result = decodeMilestone({ ...VALID_MILESTONE, tasks: [] })
    expect(result.tasks.length).toBe(0)
  })

  test('accepts a milestone with one task', () => {
    const result = decodeMilestone(VALID_MILESTONE)
    expect(result.tasks.length).toBe(1)
    expect(result.tasks[0]?.id).toBe('t-01-bar')
  })

  test('rejects a milestone missing tasks field', () => {
    const { tasks: _drop, ...rest } = VALID_MILESTONE
    expect(() => decodeMilestone(rest)).toThrow()
  })

  test('accepts multi-segment kebab id', () => {
    const result = decodeMilestone({ ...VALID_MILESTONE, id: 'ms-01-foundation' })
    expect(result.id).toBe('ms-01-foundation')
  })

  test('rejects non-kebab id', () => {
    expect(() => decodeMilestone({ ...VALID_MILESTONE, id: 'PascalCase' })).toThrow()
  })
})

describe('RoadmapProgress', () => {
  test('accepts a roadmap with version 2', () => {
    const result = decodeRoadmapProgress(VALID_ROADMAP)
    expect(result.version).toBe(2)
    expect(result.milestones.length).toBe(1)
  })

  test('rejects a roadmap missing version', () => {
    const { version: _drop, ...rest } = VALID_ROADMAP
    expect(() => decodeRoadmapProgress(rest)).toThrow()
  })

  test('rejects a roadmap with version 1', () => {
    expect(() => decodeRoadmapProgress({ ...VALID_ROADMAP, version: 1 })).toThrow()
  })

  test('rejects a roadmap with version 3', () => {
    expect(() => decodeRoadmapProgress({ ...VALID_ROADMAP, version: 3 })).toThrow()
  })
})
