import * as Fs from 'node:fs/promises'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { getGitIgnorePath } from '#@/lib/paths.ts'

import { setupTestContext } from './_test-helper.ts'
import { write } from './gitignore.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('write', () => {
  test('creates .gitignore with expected entries', async () => {
    await Effect.runPromise(write(ctx.agentsDir))

    const content = await Fs.readFile(getGitIgnorePath(ctx.agentsDir), 'utf-8')
    expect(content).toContain('.cache/')
    expect(content).toContain('skills/')
    expect(content).toContain('.gitignore')
  })

  test('overwrites existing .gitignore', async () => {
    await Fs.writeFile(getGitIgnorePath(ctx.agentsDir), 'old content\n', 'utf-8')

    await Effect.runPromise(write(ctx.agentsDir))

    const content = await Fs.readFile(getGitIgnorePath(ctx.agentsDir), 'utf-8')
    expect(content).not.toContain('old content')
    expect(content).toContain('.cache/')
  })
})
