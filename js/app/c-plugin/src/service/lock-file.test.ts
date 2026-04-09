import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { getLockFilePath } from '#@/lib/paths.ts'
import { emptyLockFile } from '#@/schema/lock-file.ts'
import type { LockFile } from '#@/schema/lock-file.ts'

import { setupTestContext } from './_test-helper.ts'
import { read, write } from './lock-file.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('read', () => {
  test('returns emptyLockFile when file does not exist', async () => {
    const result = await Effect.runPromise(read(ctx.agentsDir))
    expect(result).toStrictEqual(emptyLockFile)
  })

  test('parses valid lock file', async () => {
    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'abc123',
          marketplaceKind: 'claude',
          plugins: [
            {
              enabledSkills: ['skill-a'],
              name: 'my-plugin',
              path: 'plugins/my-plugin',
            },
          ],
          source: 'owner/repo',
          sourceType: 'github',
        },
      ],
      skillDirs: ['/custom/dir'],
      version: 1,
    }

    const filePath = getLockFilePath(ctx.agentsDir)
    await Fs.mkdir(NodePath.dirname(filePath), { recursive: true })
    await Fs.writeFile(filePath, JSON.stringify(lockFile, null, '\t'), 'utf-8')

    const result = await Effect.runPromise(read(ctx.agentsDir))
    expect(result).toStrictEqual(lockFile)
  })

  test('returns emptyLockFile when file contains corrupt JSON', async () => {
    const filePath = getLockFilePath(ctx.agentsDir)
    await Fs.mkdir(NodePath.dirname(filePath), { recursive: true })
    await Fs.writeFile(filePath, '{ invalid json }}}', 'utf-8')

    const result = await Effect.runPromise(read(ctx.agentsDir))
    expect(result).toStrictEqual(emptyLockFile)
  })

  test('returns emptyLockFile when file has invalid schema', async () => {
    const filePath = getLockFilePath(ctx.agentsDir)
    await Fs.mkdir(NodePath.dirname(filePath), { recursive: true })
    await Fs.writeFile(filePath, JSON.stringify({ invalid: true, version: 99 }), 'utf-8')

    const result = await Effect.runPromise(read(ctx.agentsDir))
    expect(result).toStrictEqual(emptyLockFile)
  })
})

describe('write', () => {
  test('write then read roundtrip', async () => {
    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'def456',
          marketplaceKind: 'claude',
          plugins: [
            {
              enabledSkills: ['skill-x', 'skill-y'],
              name: 'test-plugin',
              path: 'plugins/test-plugin',
            },
          ],
          source: 'test/repo',
          sourceType: 'github',
        },
      ],
      skillDirs: [],
      version: 1,
    }

    await Effect.runPromise(write(ctx.agentsDir, lockFile))
    const result = await Effect.runPromise(read(ctx.agentsDir))
    expect(result).toStrictEqual(lockFile)
  })

  test('does not leave .tmp file after write', async () => {
    const lockFile: LockFile = { ...emptyLockFile }

    await Effect.runPromise(write(ctx.agentsDir, lockFile))

    const filePath = getLockFilePath(ctx.agentsDir)
    const tmpPath = `${filePath}.tmp`

    await expect(Fs.access(tmpPath)).rejects.toThrow()
  })
})
