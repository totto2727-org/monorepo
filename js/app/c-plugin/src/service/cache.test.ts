import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { getCacheDir, getRepoCacheDir, getSkillsDir } from '#@/lib/paths.ts'

import { gitMock } from './_git-mock.ts'
import { setupTestContext } from './_test-helper.ts'
import { ensureDirs, ensureLocalPath, ensureRepo, removeRepo } from './cache.ts'

vi.mock('#@/service/git.ts', () => gitMock)

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('ensureDirs', () => {
  test('creates cache and skills directories', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))

    const cacheDir = getCacheDir(ctx.projectRoot)
    const skillsDir = getSkillsDir(ctx.agentsDir)

    const cacheStat = await Fs.stat(cacheDir)
    const skillsStat = await Fs.stat(skillsDir)

    expect(cacheStat.isDirectory()).toBe(true)
    expect(skillsStat.isDirectory()).toBe(true)
  })

  test('succeeds when directories already exist', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))
    await expect(Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))).resolves.toBeUndefined()
  })
})

describe('ensureRepo', () => {
  test('clones repo when not cached', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))

    const repoDir = await Effect.runPromise(ensureRepo(ctx.projectRoot, 'owner/repo'))

    expect(repoDir).toBe(getRepoCacheDir(ctx.projectRoot, 'owner/repo'))
    const stat = await Fs.stat(repoDir)
    expect(stat.isDirectory()).toBe(true)
  })

  test('returns existing directory when already cached', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))

    const repoCacheDir = getRepoCacheDir(ctx.projectRoot, 'owner/repo')
    await Fs.mkdir(repoCacheDir, { recursive: true })

    const markerFile = NodePath.join(repoCacheDir, 'marker.txt')
    await Fs.writeFile(markerFile, 'exists', 'utf-8')

    const repoDir = await Effect.runPromise(ensureRepo(ctx.projectRoot, 'owner/repo'))
    expect(repoDir).toBe(repoCacheDir)

    const content = await Fs.readFile(markerFile, 'utf-8')
    expect(content).toBe('exists')
  })
})

describe('removeRepo', () => {
  test('removes cached repository directory', async () => {
    await Effect.runPromise(ensureDirs(ctx.agentsDir, ctx.projectRoot))

    const repoCacheDir = getRepoCacheDir(ctx.projectRoot, 'owner/repo')
    await Fs.mkdir(repoCacheDir, { recursive: true })
    await Fs.writeFile(NodePath.join(repoCacheDir, 'file.txt'), 'data', 'utf-8')

    await Effect.runPromise(removeRepo(ctx.projectRoot, 'owner/repo'))
    await expect(Fs.access(repoCacheDir)).rejects.toThrow()
  })

  test('does not throw when directory does not exist', async () => {
    await expect(Effect.runPromise(removeRepo(ctx.projectRoot, 'nonexistent/repo'))).resolves.toBeUndefined()
  })
})

describe('ensureLocalPath', () => {
  test('resolves ~ to home directory when it exists', async () => {
    const resolved = await Effect.runPromise(ensureLocalPath('~', ctx.agentsDir))
    expect(resolved).toBe(Os.homedir())
  })

  test('resolves ./some/path relative to agentsRoot when it exists', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'some', 'path')
    await Fs.mkdir(targetDir, { recursive: true })

    const resolved = await Effect.runPromise(ensureLocalPath('./some/path', ctx.agentsDir))
    expect(resolved).toBe(targetDir)
  })

  test('fails with descriptive Error when path does not exist', async () => {
    await expect(Effect.runPromise(ensureLocalPath('./nonexistent', ctx.agentsDir))).rejects.toThrow(
      /Local path does not exist/,
    )
  })
})
