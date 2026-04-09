import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { getCacheDir, getRepoCacheDir, getSkillsDir } from '#@/lib/paths.ts'

import { gitMock } from './_git-mock.ts'
import { setupTestContext } from './_test-helper.ts'
import { ensureDirs, ensureRepo, removeRepo } from './cache.ts'

vi.mock('#@/service/git.ts', () => gitMock)

// eslint-disable-next-line rules/no-let -- test context reassigned in beforeEach
let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('ensureDirs', () => {
  test('creates .cache and skills directories', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir))

    const cacheDir = getCacheDir(ctx.agentsDir)
    const skillsDir = getSkillsDir(ctx.agentsDir)

    const cacheStat = await Fs.stat(cacheDir)
    const skillsStat = await Fs.stat(skillsDir)

    expect(cacheStat.isDirectory()).toBe(true)
    expect(skillsStat.isDirectory()).toBe(true)
  })

  test('succeeds when directories already exist', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir))
    await expect(Effect.runPromise(ensureDirs(ctx.agentsDir))).resolves.toBeUndefined()
  })
})

describe('ensureRepo', () => {
  test('clones repo when not cached', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir))

    const repoDir = await Effect.runPromise(ensureRepo(ctx.agentsDir, 'owner/repo'))

    expect(repoDir).toBe(getRepoCacheDir(ctx.agentsDir, 'owner/repo'))
    const stat = await Fs.stat(repoDir)
    expect(stat.isDirectory()).toBe(true)
  })

  test('returns existing directory when already cached', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir))

    const repoCacheDir = getRepoCacheDir(ctx.agentsDir, 'owner/repo')
    await Fs.mkdir(repoCacheDir, { recursive: true })

    const markerFile = NodePath.join(repoCacheDir, 'marker.txt')
    await Fs.writeFile(markerFile, 'exists', 'utf8')

    const repoDir = await Effect.runPromise(ensureRepo(ctx.agentsDir, 'owner/repo'))
    expect(repoDir).toBe(repoCacheDir)

    const content = await Fs.readFile(markerFile, 'utf8')
    expect(content).toBe('exists')
  })
})

describe('removeRepo', () => {
  test('removes cached repository directory', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir))

    const repoCacheDir = getRepoCacheDir(ctx.agentsDir, 'owner/repo')
    await Fs.mkdir(repoCacheDir, { recursive: true })
    await Fs.writeFile(NodePath.join(repoCacheDir, 'file.txt'), 'data', 'utf8')

    await Effect.runPromise(removeRepo(ctx.agentsDir, 'owner/repo'))
    await expect(Fs.access(repoCacheDir)).rejects.toThrow()
  })

  test('does not throw when directory does not exist', async () => {
    await expect(Effect.runPromise(removeRepo(ctx.agentsDir, 'nonexistent/repo'))).resolves.toBeUndefined()
  })
})
