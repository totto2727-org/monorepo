import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { getSkillsDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'

import { gitMock } from './_git-mock.ts'
import { buildFakeRepoFixture, ensureAgentsDirs, setupTestContext, writeLockFile } from './_test-helper.ts'
import { read as readLockFile } from './lock-file.ts'
import { run } from './sync.ts'

vi.mock('#@/service/git.ts', () => gitMock)

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
  await ensureAgentsDirs(ctx.agentsDir)
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('sync run', () => {
  test('exits early when lock file has no repositories', async () => {
    const lockFile: LockFile = {
      repositories: [],
      skillDirs: [],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await expect(Effect.runPromise(run(ctx.agentsDir))).resolves.toBeUndefined()
  })

  test('creates symlinks for enabled skills', async () => {
    await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: ['skill-a', 'skill-b'],
          source: 'plugins/my-plugin',
        },
      ],
    })

    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'abc123',
          marketplaceKind: 'claude',
          plugins: [
            {
              enabledSkills: ['skill-a', 'skill-b'],
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

    const skillsDir = getSkillsDir(ctx.agentsDir)
    const linkA = await Fs.lstat(NodePath.join(skillsDir, 'skill-a'))
    const linkB = await Fs.lstat(NodePath.join(skillsDir, 'skill-b'))
    expect(linkA.isSymbolicLink()).toBe(true)
    expect(linkB.isSymbolicLink()).toBe(true)
  })

  test('removes symlinks for skills no longer in repo', async () => {
    await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: ['skill-a'],
          source: 'plugins/my-plugin',
        },
      ],
    })

    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'abc123',
          marketplaceKind: 'claude',
          plugins: [
            {
              enabledSkills: ['skill-a', 'skill-removed'],
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

    const skillsDir = getSkillsDir(ctx.agentsDir)
    const linkA = await Fs.lstat(NodePath.join(skillsDir, 'skill-a'))
    expect(linkA.isSymbolicLink()).toBe(true)

    await expect(Fs.lstat(NodePath.join(skillsDir, 'skill-removed'))).rejects.toThrow()

    const updatedLockFile = await Effect.runPromise(readLockFile(ctx.agentsDir))
    const plugin = updatedLockFile.repositories[0]?.plugins[0]
    expect(plugin?.enabledSkills).toStrictEqual(['skill-a'])
  })

  test('removes plugin entry when all skills are removed', async () => {
    await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: [],
          source: 'plugins/my-plugin',
        },
      ],
    })

    const lockFile: LockFile = {
      repositories: [
        {
          commitHash: 'abc123',
          marketplaceKind: 'claude',
          plugins: [
            {
              enabledSkills: ['gone-skill'],
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

    const updatedLockFile = await Effect.runPromise(readLockFile(ctx.agentsDir))
    expect(updatedLockFile.repositories).toHaveLength(0)
  })

  test('creates symlinks in additional skillDirs', async () => {
    const extraDir = NodePath.join(ctx.agentsDir, 'extra-skills')
    await Fs.mkdir(extraDir, { recursive: true })

    await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: ['skill-a'],
          source: 'plugins/my-plugin',
        },
      ],
    })

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
      skillDirs: [extraDir],
      version: 1,
    }
    await writeLockFile(ctx.agentsDir, lockFile)

    await Effect.runPromise(run(ctx.agentsDir))

    const extraLink = await Fs.lstat(NodePath.join(extraDir, 'skill-a'))
    expect(extraLink.isSymbolicLink()).toBe(true)
  })

  test('syncs local repo without invoking git', async () => {
    const localRepoDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-local-'))
    try {
      const marketplaceDir = NodePath.join(localRepoDir, '.claude-plugin')
      await Fs.mkdir(marketplaceDir, { recursive: true })
      const marketplace = {
        name: 'local-marketplace',
        plugins: [{ name: 'local-plugin', source: 'plugins/local-plugin' }],
      }
      await Fs.writeFile(
        NodePath.join(marketplaceDir, 'marketplace.json'),
        JSON.stringify(marketplace, null, '\t'),
        'utf-8',
      )

      const skillDir = NodePath.join(localRepoDir, 'plugins', 'local-plugin', 'skills', 'local-skill')
      await Fs.mkdir(skillDir, { recursive: true })
      await Fs.writeFile(NodePath.join(skillDir, 'SKILL.md'), '# local-skill\n', 'utf-8')

      const lockFile: LockFile = {
        repositories: [
          {
            marketplaceKind: 'claude',
            plugins: [
              {
                enabledSkills: ['local-skill'],
                name: 'local-plugin',
                path: 'plugins/local-plugin',
              },
            ],
            source: localRepoDir,
            sourceType: 'local',
          },
        ],
        skillDirs: [],
        version: 1,
      }
      await writeLockFile(ctx.agentsDir, lockFile)

      await Effect.runPromise(run(ctx.agentsDir))

      const skillsDir = getSkillsDir(ctx.agentsDir)
      const link = await Fs.lstat(NodePath.join(skillsDir, 'local-skill'))
      expect(link.isSymbolicLink()).toBe(true)

      const resolved = await Fs.realpath(NodePath.join(skillsDir, 'local-skill'))
      const expected = await Fs.realpath(
        NodePath.join(localRepoDir, 'plugins', 'local-plugin', 'skills', 'local-skill'),
      )
      expect(resolved).toBe(expected)
    } finally {
      await Fs.rm(localRepoDir, { force: true, recursive: true })
    }
  })
})
