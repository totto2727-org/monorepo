import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import type { LockFile } from '#@/schema/lock-file.ts'

import { removeRepoCaches } from './remove.ts'

const { mockRemoveRepo } = vi.hoisted(() => ({
  mockRemoveRepo: vi.fn(() => Effect.void),
}))

vi.mock('#@/service/cache.ts', () => ({
  removeRepo: mockRemoveRepo,
}))

beforeEach(() => {
  mockRemoveRepo.mockClear()
})

describe('removeRepoCaches', () => {
  test('skips local repos', async () => {
    const lockFile: LockFile = {
      repositories: [
        {
          marketplaceKind: 'claude',
          plugins: [],
          source: '~/local-plugin',
          sourceType: 'local',
        },
      ],
      skillDirs: [],
      version: 1,
    }

    await Effect.runPromise(
      removeRepoCaches('/tmp/agents', lockFile, new Set(['~/local-plugin'])).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(mockRemoveRepo).not.toHaveBeenCalled()
  })

  test('removes github repos from cache', async () => {
    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'abc123',
          marketplaceKind: 'claude',
          plugins: [],
          source: 'owner/repo',
          sourceType: 'github',
        },
      ],
      skillDirs: [],
      version: 1,
    }

    await Effect.runPromise(
      removeRepoCaches('/tmp/agents', lockFile, new Set(['owner/repo'])).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(mockRemoveRepo).toHaveBeenCalledTimes(1)
    expect(mockRemoveRepo).toHaveBeenCalledWith('/tmp/agents', 'owner/repo')
  })
})
