import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { getSkillsDir } from '#@/lib/paths.ts'

import { ensureAgentsDirs, setupTestContext } from './_test-helper.ts'
import { createSkillLink, listSkillLinks, removeSkillLink, removeSkillLinkFromDirs } from './symlink.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
  await ensureAgentsDirs(ctx.agentsDir)
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('createSkillLink', () => {
  test('creates symlink in primary skills directory', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'repo', 'plugins', 'p', 'skills', 'my-skill')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir))

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const stat = await Fs.lstat(linkPath)
    expect(stat.isSymbolicLink()).toBe(true)
  })

  test('creates symlinks in additional skillDirs', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'repo', 'plugins', 'p', 'skills', 'my-skill')
    await Fs.mkdir(targetDir, { recursive: true })

    const extraDir = NodePath.join(ctx.agentsDir, 'extra-skills')
    await Fs.mkdir(extraDir, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [extraDir], 'my-skill', targetDir))

    const primaryLink = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const extraLink = NodePath.join(extraDir, 'my-skill')

    const primaryStat = await Fs.lstat(primaryLink)
    expect(primaryStat.isSymbolicLink()).toBe(true)
    const extraStat = await Fs.lstat(extraLink)
    expect(extraStat.isSymbolicLink()).toBe(true)
  })

  test('overwrites existing symlink without error', async () => {
    const targetDir1 = NodePath.join(ctx.agentsDir, 'target1')
    const targetDir2 = NodePath.join(ctx.agentsDir, 'target2')
    await Fs.mkdir(targetDir1, { recursive: true })
    await Fs.mkdir(targetDir2, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir1))
    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir2))

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const stat = await Fs.lstat(linkPath)
    expect(stat.isSymbolicLink()).toBe(true)
  })
})

describe('removeSkillLink', () => {
  test('removes existing symlink', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir))
    await Effect.runPromise(removeSkillLink(ctx.agentsDir, [], 'my-skill'))

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    await expect(Fs.lstat(linkPath)).rejects.toThrow()
  })

  test('does not throw when symlink does not exist', async () => {
    await expect(Effect.runPromise(removeSkillLink(ctx.agentsDir, [], 'nonexistent'))).resolves.toBeUndefined()
  })
})

describe('removeSkillLinkFromDirs', () => {
  test('removes symlinks only from specified directories', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    const extraDir = NodePath.join(ctx.agentsDir, 'extra-skills')

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [extraDir], 'my-skill', targetDir))
    await Effect.runPromise(removeSkillLinkFromDirs([extraDir], 'my-skill'))

    const primaryLink = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const extraLink = NodePath.join(extraDir, 'my-skill')

    const primaryStat = await Fs.lstat(primaryLink)
    expect(primaryStat.isSymbolicLink()).toBe(true)
    await expect(Fs.lstat(extraLink)).rejects.toThrow()
  })
})

describe('listSkillLinks', () => {
  test('returns symlink names', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'skill-a', targetDir))
    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'skill-b', targetDir))

    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir))
    expect([...links].toSorted()).toStrictEqual(['skill-a', 'skill-b'])
  })

  test('excludes non-symlink entries', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(createSkillLink(ctx.agentsDir, [], 'skill-a', targetDir))

    const regularFile = NodePath.join(getSkillsDir(ctx.agentsDir), 'not-a-link')
    await Fs.writeFile(regularFile, '', 'utf8')

    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir))
    expect([...links]).toStrictEqual(['skill-a'])
  })

  test('returns empty array when skills directory does not exist', async () => {
    await Fs.rm(getSkillsDir(ctx.agentsDir), { force: true, recursive: true })
    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir))
    expect([...links]).toStrictEqual([])
  })
})
