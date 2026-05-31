import { Schema } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { Milestone, Task } from '#@/feature/schema/current.ts'

import { findTask } from './task.ts'

const buildTask = (overrides: Partial<typeof Task.Encoded> = {}) =>
  Schema.decodeUnknownSync(Task)({
    id: 't-01-foo',
    notes: null,
    prs: [],
    status: 'planned',
    title: 'Foo',
    workflow_identifiers: [],
    ...overrides,
  })

const buildMilestone = (tasks: readonly (typeof Task.Type)[]) =>
  Schema.decodeUnknownSync(Milestone)({
    depends_on: [],
    id: 'ms-01-foo',
    notes: null,
    prs: [],
    status: 'planned',
    tasks: tasks.map((t) => Schema.encodeSync(Task)(t)),
    title: 'Foo',
    workflow_identifiers: [],
  })

describe('findTask', () => {
  test('returns the task whose id matches', () => {
    const target = buildTask({ id: 't-02-bar', title: 'Bar' })
    const milestone = buildMilestone([buildTask({ id: 't-01-foo' }), target, buildTask({ id: 't-03-baz' })])
    expect(findTask(milestone, 't-02-bar')).toStrictEqual(target)
  })

  test('returns undefined when id is not present', () => {
    const milestone = buildMilestone([buildTask({ id: 't-01-foo' })])
    expect(findTask(milestone, 't-99-missing')).toBeUndefined()
  })

  test('returns undefined when tasks array is empty', () => {
    const milestone = buildMilestone([])
    expect(findTask(milestone, 't-01-foo')).toBeUndefined()
  })
})
