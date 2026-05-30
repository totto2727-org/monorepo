import { Effect } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { migrate } from './migrate.ts'

const buildV1Raw = (overrides: Record<string, unknown> = {}) => ({
  created_at: '2026-05-15T16:15:13.160Z',
  milestones: [
    {
      depends_on: [],
      id: 'ms-01-foo',
      notes: null,
      prs: [],
      status: 'planned',
      title: 'Foo',
      workflow_identifiers: [],
    },
  ],
  prs: [],
  roadmap_id: 'alpha',
  status: 'planned',
  title: 'Alpha',
  updated_at: '2026-05-15T16:15:13.160Z',
  ...overrides,
})

const buildV2Raw = (overrides: Record<string, unknown> = {}) => ({
  created_at: '2026-05-15T16:15:13.160Z',
  milestones: [
    {
      depends_on: [],
      id: 'ms-01-foo',
      notes: null,
      prs: [],
      status: 'planned',
      tasks: [
        {
          id: 't-01-bar',
          notes: null,
          prs: [],
          status: 'planned',
          title: 'Bar',
          workflow_identifiers: [],
        },
      ],
      title: 'Foo',
      workflow_identifiers: [],
    },
  ],
  prs: [],
  roadmap_id: 'alpha',
  status: 'planned',
  title: 'Alpha',
  updated_at: '2026-05-15T16:15:13.160Z',
  version: 2,
  ...overrides,
})

describe('migrate (v1 detection)', () => {
  test('treats missing version field as v1', async () => {
    const result = await Effect.runPromise(migrate(buildV1Raw()))
    expect(result.version).toBe(2)
  })

  test('v1 milestones receive an empty tasks array', async () => {
    const result = await Effect.runPromise(migrate(buildV1Raw()))
    expect(result.milestones[0]?.tasks).toEqual([])
  })

  test('v1 scalar fields survive migration unchanged', async () => {
    const result = await Effect.runPromise(migrate(buildV1Raw()))
    expect(result.roadmap_id).toBe('alpha')
    expect(result.title).toBe('Alpha')
    expect(result.status).toBe('planned')
  })
})

describe('migrate (v2 passthrough)', () => {
  test('decodes a v2 input as v2', async () => {
    const result = await Effect.runPromise(migrate(buildV2Raw()))
    expect(result.version).toBe(2)
  })

  test('preserves an existing tasks array', async () => {
    const result = await Effect.runPromise(migrate(buildV2Raw()))
    expect(result.milestones[0]?.tasks.length).toBe(1)
    expect(result.milestones[0]?.tasks[0]?.id).toBe('t-01-bar')
  })
})

describe('migrate (rejection)', () => {
  test('fails for non-object input', async () => {
    const exit = await Effect.runPromiseExit(migrate(null))
    expect(exit._tag).toBe('Failure')
  })

  test('fails for unknown future version', async () => {
    const exit = await Effect.runPromiseExit(migrate(buildV2Raw({ version: 99 })))
    expect(exit._tag).toBe('Failure')
  })

  test('fails for non-numeric version', async () => {
    const exit = await Effect.runPromiseExit(migrate(buildV2Raw({ version: 'two' })))
    expect(exit._tag).toBe('Failure')
  })
})
