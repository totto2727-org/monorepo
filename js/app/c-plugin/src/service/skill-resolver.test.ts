import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect, Exit } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { buildFakeRepoFixture, ensureAgentsDirs, setupTestContext } from './_test-helper.ts'
import { resolveFromRepo } from './skill-resolver.ts'

// eslint-disable-next-line rules/no-let -- test context reassigned in beforeEach
let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
  await ensureAgentsDirs(ctx.agentsDir)
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('resolveFromRepo', () => {
  test('resolves skills from valid repo structure', async () => {
    const repoDir = await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: ['skill-a', 'skill-b'],
          source: 'plugins/my-plugin',
        },
      ],
    })

    const skills = await Effect.runPromise(resolveFromRepo(repoDir, 'claude'))

    expect(skills).toHaveLength(2)
    expect(skills.map((s) => s.skillName).toSorted()).toStrictEqual(['skill-a', 'skill-b'])
    expect(skills[0]?.pluginName).toBe('my-plugin')
  })

  test('resolves skills from multiple plugins', async () => {
    const repoDir = await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'plugin-a',
          skills: ['skill-1'],
          source: 'plugins/plugin-a',
        },
        {
          name: 'plugin-b',
          skills: ['skill-2', 'skill-3'],
          source: 'plugins/plugin-b',
        },
      ],
    })

    const skills = await Effect.runPromise(resolveFromRepo(repoDir, 'claude'))
    expect(skills).toHaveLength(3)
  })

  test('excludes directories without SKILL.md', async () => {
    const repoDir = await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'my-plugin',
          skills: ['valid-skill'],
          source: 'plugins/my-plugin',
        },
      ],
    })

    const noSkillMdDir = NodePath.join(repoDir, 'plugins', 'my-plugin', 'skills', 'no-skill-md')
    await Fs.mkdir(noSkillMdDir, { recursive: true })

    const skills = await Effect.runPromise(resolveFromRepo(repoDir, 'claude'))
    expect(skills).toHaveLength(1)
    expect(skills[0]?.skillName).toBe('valid-skill')
  })

  test('returns empty when plugin has no skills directory', async () => {
    const repoDir = await buildFakeRepoFixture(ctx.agentsDir, 'owner/repo', {
      plugins: [
        {
          name: 'empty-plugin',
          skills: [],
          source: 'plugins/empty-plugin',
        },
      ],
    })

    const skills = await Effect.runPromise(resolveFromRepo(repoDir, 'claude'))
    expect(skills).toHaveLength(0)
  })

  test('fails when marketplace.json is missing', async () => {
    const repoDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'no-marketplace')
    await Fs.mkdir(repoDir, { recursive: true })

    const exit = await Effect.runPromiseExit(resolveFromRepo(repoDir, 'claude'))
    expect(Exit.isFailure(exit)).toBe(true)
  })

  test('fails when marketplace.json has invalid schema', async () => {
    const repoDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'bad-schema')
    const marketplaceDir = NodePath.join(repoDir, '.claude-plugin')
    await Fs.mkdir(marketplaceDir, { recursive: true })
    await Fs.writeFile(NodePath.join(marketplaceDir, 'marketplace.json'), JSON.stringify({ invalid: true }), 'utf8')

    const exit = await Effect.runPromiseExit(resolveFromRepo(repoDir, 'claude'))
    expect(Exit.isFailure(exit)).toBe(true)
  })
})
