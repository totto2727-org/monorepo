import { Schema } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { RoadmapProgress } from '#@/schema/progress.ts'

import { mergePrs, progressFilePath, renderProgressYaml } from './progress.ts'

const buildRoadmap = (overrides: Partial<typeof RoadmapProgress.Encoded> = {}) =>
  Schema.decodeUnknownSync(RoadmapProgress)({
    created_at: '2026-05-15T16:15:13.160Z',
    milestones: [],
    prs: [],
    roadmap_id: 'roadmap-cli',
    status: 'planned',
    title: 'Roadmap management CLI',
    updated_at: '2026-05-15T16:15:13.160Z',
    ...overrides,
  })

describe('progressFilePath', () => {
  test('joins dir, roadmap id and progress.yaml filename', () => {
    expect(progressFilePath('docs/roadmap', 'roadmap-cli')).toBe('docs/roadmap/roadmap-cli/progress.yaml')
  })

  test('normalizes trailing slash on dir', () => {
    expect(progressFilePath('docs/roadmap/', 'roadmap-cli')).toBe('docs/roadmap/roadmap-cli/progress.yaml')
  })

  test('handles absolute dir', () => {
    expect(progressFilePath('/abs/roadmap', 'alpha')).toBe('/abs/roadmap/alpha/progress.yaml')
  })

  test('handles "." as dir', () => {
    expect(progressFilePath('.', 'alpha')).toBe('alpha/progress.yaml')
  })
})

describe('renderProgressYaml', () => {
  test('renders header comment as first lines', () => {
    const yaml = renderProgressYaml(buildRoadmap())
    expect(yaml.startsWith('# Roadmap progress tracking yaml managed by the `roadmap` CLI.\n')).toBe(true)
  })

  test('renders an empty milestones array as "milestones: []"', () => {
    const yaml = renderProgressYaml(buildRoadmap())
    expect(yaml).toContain('milestones: []')
  })

  test('renders ISO timestamps for created_at and updated_at', () => {
    const yaml = renderProgressYaml(
      buildRoadmap({
        created_at: '2026-01-02T03:04:05.678Z',
        updated_at: '2026-09-10T11:12:13.000Z',
      }),
    )
    expect(yaml).toContain("created_at: '2026-01-02T03:04:05.678Z'")
    expect(yaml).toContain("updated_at: '2026-09-10T11:12:13.000Z'")
  })

  test('renders all scalar fields exactly once', () => {
    const yaml = renderProgressYaml(
      buildRoadmap({
        roadmap_id: 'alpha',
        status: 'active',
        title: 'Alpha',
      }),
    )
    expect(yaml).toContain('roadmap_id: alpha')
    expect(yaml).toContain('status: active')
    expect(yaml).toContain('title: Alpha')
  })

  test('renders a roadmap with prs as a YAML sequence', () => {
    const yaml = renderProgressYaml(
      buildRoadmap({
        prs: ['https://example.com/pr/1', '#42'],
      }),
    )
    expect(yaml).toContain('prs:\n  - https://example.com/pr/1\n  - ')
    expect(yaml).toContain("'#42'")
  })

  test('renders a milestone block under milestones with nested prs and depends_on', () => {
    const yaml = renderProgressYaml(
      buildRoadmap({
        milestones: [
          {
            depends_on: ['ms-00-foo'],
            id: 'ms-01-bar',
            notes: null,
            prs: ['https://example.com/pr/3'],
            status: 'completed',
            title: 'Bar',
            workflow_identifiers: ['wf-2026'],
          },
        ],
      }),
    )
    expect(yaml).toContain('  - depends_on:\n      - ms-00-foo\n')
    expect(yaml).toContain('    id: ms-01-bar\n')
    expect(yaml).toContain('    notes: null\n')
    expect(yaml).toContain('    prs:\n      - https://example.com/pr/3\n')
    expect(yaml).toContain('    status: completed\n')
    expect(yaml).toContain('    title: Bar\n')
    expect(yaml).toContain('    workflow_identifiers:\n      - wf-2026\n')
  })
})

describe('mergePrs', () => {
  test('replaces existing list when append is false', () => {
    expect(mergePrs(['old-1', 'old-2'], ['new-1'], false)).toStrictEqual(['new-1'])
  })

  test('replaces with empty incoming when append is false', () => {
    expect(mergePrs(['old-1', 'old-2'], [], false)).toStrictEqual([])
  })

  test('returns a fresh array when replacing (not the incoming reference)', () => {
    const incoming = ['x']
    const result = mergePrs([], incoming, false)
    expect(result).toStrictEqual(['x'])
    expect(result).not.toBe(incoming)
  })

  test('appends incoming to existing when append is true', () => {
    expect(mergePrs(['old-1'], ['new-1', 'new-2'], true)).toStrictEqual(['old-1', 'new-1', 'new-2'])
  })

  test('drops duplicates already present in existing when appending', () => {
    expect(mergePrs(['pr-1', 'pr-2'], ['pr-2', 'pr-3'], true)).toStrictEqual(['pr-1', 'pr-2', 'pr-3'])
  })

  test('drops duplicates within the incoming list when appending', () => {
    expect(mergePrs(['pr-1'], ['pr-2', 'pr-2', 'pr-3'], true)).toStrictEqual(['pr-1', 'pr-2', 'pr-3'])
  })

  test('preserves existing order when appending', () => {
    expect(mergePrs(['b', 'a', 'c'], ['d'], true)).toStrictEqual(['b', 'a', 'c', 'd'])
  })

  test('returns existing copy when appending empty incoming', () => {
    expect(mergePrs(['pr-1'], [], true)).toStrictEqual(['pr-1'])
  })
})
