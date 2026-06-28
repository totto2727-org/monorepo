import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { getSkillsDir } from '#@/lib/paths.ts'

import { ensureAgentsDirs, setupTestContext } from './_test-helper.ts'
import { createSkillLink, listSkillLinks, removeSkillLink, removeSkillLinkFromDirs } from './symlink.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
  await ensureAgentsDirs(ctx.agentsDir, ctx.projectRoot)
})

afterEach(async () => {
  await ctx.cleanup()
})

describe('createSkillLink', () => {
  test('creates symlink in primary skills directory', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'repo', 'plugins', 'p', 'skills', 'my-skill')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    expect(
      await Fs.lstat(linkPath).then(
        (stat) => stat.isSymbolicLink(),
        () => false,
      ),
    ).toBe(true)
  })

  test('creates symlinks in additional skillDirs relative to the lock file directory', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, '.cache', 'owner', 'repo', 'plugins', 'p', 'skills', 'my-skill')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, ['extra-skills'], 'my-skill', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )

    const primaryLink = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const extraLink = NodePath.join(ctx.projectRoot, 'extra-skills', 'my-skill')

    expect(
      await Fs.lstat(primaryLink).then(
        (stat) => stat.isSymbolicLink(),
        () => false,
      ),
    ).toBe(true)
    expect(
      await Fs.lstat(extraLink).then(
        (stat) => stat.isSymbolicLink(),
        () => false,
      ),
    ).toBe(true)
  })

  test('overwrites existing symlink without error', async () => {
    const targetDir1 = NodePath.join(ctx.agentsDir, 'target1')
    const targetDir2 = NodePath.join(ctx.agentsDir, 'target2')
    await Fs.mkdir(targetDir1, { recursive: true })
    await Fs.mkdir(targetDir2, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir1).pipe(Effect.provide(NodeServices.layer)),
    )
    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir2).pipe(Effect.provide(NodeServices.layer)),
    )

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    expect(
      await Fs.lstat(linkPath).then(
        (stat) => stat.isSymbolicLink(),
        () => false,
      ),
    ).toBe(true)
  })
})

describe('removeSkillLink', () => {
  test('removes existing symlink', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'my-skill', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )
    await Effect.runPromise(removeSkillLink(ctx.agentsDir, [], 'my-skill').pipe(Effect.provide(NodeServices.layer)))

    const linkPath = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    expect(
      await Fs.access(linkPath).then(
        () => true,
        () => false,
      ),
    ).toBe(false)
  })

  test('does not throw when symlink does not exist', async () => {
    await expect(
      Effect.runPromise(removeSkillLink(ctx.agentsDir, [], 'nonexistent').pipe(Effect.provide(NodeServices.layer))),
    ).resolves.toBeUndefined()
  })
})

describe('removeSkillLinkFromDirs', () => {
  test('removes symlinks only from specified directories', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    const extraDir = NodePath.join(ctx.projectRoot, 'extra-skills')

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, ['extra-skills'], 'my-skill', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )
    await Effect.runPromise(
      removeSkillLinkFromDirs(['extra-skills'], ctx.projectRoot, 'my-skill').pipe(Effect.provide(NodeServices.layer)),
    )

    const primaryLink = NodePath.join(getSkillsDir(ctx.agentsDir), 'my-skill')
    const extraLink = NodePath.join(extraDir, 'my-skill')

    expect(
      await Fs.lstat(primaryLink).then(
        (stat) => stat.isSymbolicLink(),
        () => false,
      ),
    ).toBe(true)
    expect(
      await Fs.access(extraLink).then(
        () => true,
        () => false,
      ),
    ).toBe(false)
  })
})

describe('listSkillLinks', () => {
  test('returns symlink names', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'skill-a', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )
    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'skill-b', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )

    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect([...links].toSorted()).toStrictEqual(['skill-a', 'skill-b'])
  })

  test('excludes non-symlink entries', async () => {
    const targetDir = NodePath.join(ctx.agentsDir, 'target')
    await Fs.mkdir(targetDir, { recursive: true })

    await Effect.runPromise(
      createSkillLink(ctx.agentsDir, [], 'skill-a', targetDir).pipe(Effect.provide(NodeServices.layer)),
    )

    const regularFile = NodePath.join(getSkillsDir(ctx.agentsDir), 'not-a-link')
    await Fs.writeFile(regularFile, '', 'utf-8')

    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect([...links]).toStrictEqual(['skill-a'])
  })

  test('returns empty array when skills directory does not exist', async () => {
    await Fs.rm(getSkillsDir(ctx.agentsDir), { force: true, recursive: true })
    const links = await Effect.runPromise(listSkillLinks(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect([...links]).toStrictEqual([])
  })
})
