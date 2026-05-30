import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import type { LockFile } from '#@/schema/lock-file.ts'

import { gitMock } from './_git-mock.ts'
import { ensureAgentsDirs, setupTestContext, writeLockFile } from './_test-helper.ts'
import { read as readLockFile } from './lock-file.ts'
import { run } from './update.ts'

vi.mock('#@/service/git.ts', () => gitMock)
vi.mock('#@/service/sync.ts', () => ({
  run: () => Effect.void,
}))

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
  await ensureAgentsDirs(ctx.agentsDir, ctx.projectRoot)
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('update run', () => {
  test('exits early when lock file has no repositories', async () => {
    const lockFile: LockFile = {
      repositories: [],
      skillDirs: [],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await expect(Effect.runPromise(run(ctx.agentsDir))).resolves.toBeUndefined()
  })

  test('updates commitHash for github repos', async () => {
    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'old-hash',
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
      skillDirs: [],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await Effect.runPromise(run(ctx.agentsDir))

    const updated = await Effect.runPromise(readLockFile(ctx.agentsDir))
    const [repo] = updated.repositories
    expect(repo?.sourceType).toBe('github')
    if (repo?.sourceType === 'github') {
      expect(repo.commitHash).toBe('mock-commit-hash')
    }
  })

  test('preserves local repos unchanged without adding commitHash', async () => {
    const localEntry = {
      marketplaceKind: 'claude',
      plugins: [
        {
          enabledSkills: ['skill-x'],
          name: 'local-plugin',
          path: '~/local-plugin',
        },
      ],
      source: './local-plugin',
      sourceType: 'local',
    } as const

    const lockFile: LockFile = {
      repositories: [localEntry],
      skillDirs: [],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await Effect.runPromise(run(ctx.agentsDir))

    const updated = await Effect.runPromise(readLockFile(ctx.agentsDir))
    expect(updated.repositories).toHaveLength(1)
    const [repo] = updated.repositories
    expect(repo).toStrictEqual(localEntry)
    expect(repo && 'commitHash' in repo).toBe(false)
  })

  test('handles mixed github and local repos', async () => {
    const githubEntry = {
      commitHash: 'old-hash',
      marketplaceKind: 'claude',
      plugins: [],
      source: 'owner/repo',
      sourceType: 'github',
    } as const

    const localEntry = {
      marketplaceKind: 'claude',
      plugins: [],
      source: './local-plugin',
      sourceType: 'local',
    } as const

    const lockFile: LockFile = {
      repositories: [githubEntry, localEntry],
      skillDirs: [],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await Effect.runPromise(run(ctx.agentsDir))

    const updated = await Effect.runPromise(readLockFile(ctx.agentsDir))
    expect(updated.repositories).toHaveLength(2)

    const github = updated.repositories.find((r) => r.sourceType === 'github')
    const local = updated.repositories.find((r) => r.sourceType === 'local')
    expect(github?.sourceType).toBe('github')
    if (github?.sourceType === 'github') {
      expect(github.commitHash).toBe('mock-commit-hash')
    }
    expect(local).toStrictEqual(localEntry)
  })

  test('succeeds for all-local lock file even when git is not installed', async () => {
    const original = gitMock.checkInstalled
    const failing = Object.assign(gitMock, {
      checkInstalled: Effect.fail(new gitMock.GitError('git not installed')),
    })

    try {
      const localEntry = {
        marketplaceKind: 'claude',
        plugins: [],
        source: './local-plugin',
        sourceType: 'local',
      } as const

      const lockFile: LockFile = {
        repositories: [localEntry],
        skillDirs: [],
        version: 1,
      }
      await writeLockFile(ctx.agentsDir, lockFile)

      await expect(Effect.runPromise(run(ctx.agentsDir))).resolves.toBeUndefined()
    } finally {
      Object.assign(failing, { checkInstalled: original })
    }
  })
})
