import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { isLocalPath } from '#@/lib/paths.ts'
import { hasSupportedPluginFormat } from '#@/lib/plugin-format.ts'
import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'

import { addCommand } from './add.ts'

const { mockEnsureDirs, mockEnsureRepo } = vi.hoisted(() => ({
  mockEnsureDirs: vi.fn(() => Effect.void),
  mockEnsureRepo: vi.fn((_agentsDir: string, source: string) => Effect.succeed(source)),
}))

vi.mock('#@/service/cache.ts', () => ({
  ensureDirs: mockEnsureDirs,
  ensureRepo: mockEnsureRepo,
}))

beforeEach(() => {
  mockEnsureDirs.mockClear()
  mockEnsureRepo.mockClear()
})

describe('add module', () => {
  test('addCommand is importable', () => {
    expect(addCommand).toBeDefined()
  })
})

describe('isLocalPath (add local-flow validation)', () => {
  test('rejects absolute path', () => {
    expect(isLocalPath('/abs/path')).toBe(false)
  })

  test('rejects bare relative path', () => {
    expect(isLocalPath('foo/bar')).toBe(false)
  })

  test('rejects parent traversal', () => {
    expect(isLocalPath('../up')).toBe(false)
  })

  test('rejects lone "~"', () => {
    expect(isLocalPath('~')).toBe(false)
  })

  test('rejects "~/foo" home-prefixed path', () => {
    expect(isLocalPath('~/foo')).toBe(false)
  })

  test('accepts "./foo" explicit relative path', () => {
    expect(isLocalPath('./foo')).toBe(true)
  })
})

describe('hasSupportedPluginFormat (add local-flow target check)', () => {
  const tmpDirs: string[] = []

  afterEach(async () => {
    await Promise.all(tmpDirs.splice(0).map((dir) => Fs.rm(dir, { force: true, recursive: true })))
  })

  const mkTmp = async (): Promise<string> => {
    const dir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-add-test-'))
    tmpDirs.push(dir)
    return dir
  }

  test('returns true when target has a supported plugin config dir', async () => {
    for (const kind of allKinds) {
      const dir = await mkTmp()
      await Fs.mkdir(NodePath.join(dir, getKindConfig(kind).configDir))
      await expect(hasSupportedPluginFormat(dir)).resolves.toBe(true)
    }
  })

  test('returns false when target has no plugin config dir', async () => {
    const dir = await mkTmp()
    await expect(hasSupportedPluginFormat(dir)).resolves.toBe(false)
  })

  test('returns false when target directory does not exist', async () => {
    const dir = await mkTmp()
    await expect(hasSupportedPluginFormat(NodePath.join(dir, 'missing'))).resolves.toBe(false)
  })
})
