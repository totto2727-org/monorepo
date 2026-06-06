import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { LOCK_FILE_NAME } from '#@/lib/paths.ts'

import { setupTestContext } from './_test-helper.ts'
import { collectAgentsDirs, resolveAgentsDirs } from './discover.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

// ctx.agentsDir is used as the project root (workspace dir)
beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

const writeLockFile = async (rootDir: string): Promise<string> => {
  await Fs.mkdir(rootDir, { recursive: true })
  await Fs.writeFile(NodePath.join(rootDir, LOCK_FILE_NAME), '{}', 'utf-8')
  return NodePath.join(rootDir, '.agents')
}

describe('collectAgentsDirs', () => {
  test('maps a lock file in the start directory to its .agents directory', async () => {
    const agentsDir = await writeLockFile(ctx.agentsDir)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect(result).toContain(agentsDir)
  })

  test('maps lock files in subdirectories to their .agents directories', async () => {
    const subDir = NodePath.join(ctx.agentsDir, 'packages', 'pkg-a')
    const subAgentsDir = await writeLockFile(subDir)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect(result).toContain(subAgentsDir)
  })

  test('maps multiple sibling lock files to their .agents directories', async () => {
    const agentsDirA = await writeLockFile(NodePath.join(ctx.agentsDir, 'packages', 'pkg-a'))
    const agentsDirB = await writeLockFile(NodePath.join(ctx.agentsDir, 'packages', 'pkg-b'))

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect(result).toContain(agentsDirA)
    expect(result).toContain(agentsDirB)
  })

  test('does not recurse into directories ignored by .gitignore', async () => {
    const agentsDir = await writeLockFile(ctx.agentsDir)
    await Fs.writeFile(NodePath.join(ctx.agentsDir, '.gitignore'), '.agents/\n', 'utf-8')
    const nestedAgentsDir = NodePath.join(agentsDir, '.cache', 'repo', '.agents')
    await writeLockFile(NodePath.dirname(nestedAgentsDir))

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect(result).toContain(agentsDir)
    expect(result).not.toContain(nestedAgentsDir)
  })

  test('returns empty array when no lock files are found', async () => {
    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir).pipe(Effect.provide(NodeServices.layer)))
    expect(result).toStrictEqual([])
  })
})

describe('resolveAgentsDirs', () => {
  test('non-recursive mode uses the nearest ancestor lock file', async () => {
    const rootAgentsDir = await writeLockFile(ctx.agentsDir)
    const nestedRoot = NodePath.join(ctx.agentsDir, 'packages', 'pkg-a')
    const nestedAgentsDir = await writeLockFile(nestedRoot)
    const startDir = NodePath.join(nestedRoot, 'src', 'deep')
    await Fs.mkdir(startDir, { recursive: true })

    const result = await Effect.runPromise(
      resolveAgentsDirs(false, startDir, { searchTopDir: ctx.projectRoot }).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toStrictEqual([nestedAgentsDir])
    expect(result).not.toContain(rootAgentsDir)
  })

  test('recursive mode anchors at the nearest ancestor lock and then scans descendant locks', async () => {
    const workspaceAgentsDir = await writeLockFile(ctx.agentsDir)
    const childAgentsDir = await writeLockFile(NodePath.join(ctx.agentsDir, 'packages', 'pkg-a'))
    const grandchildAgentsDir = await writeLockFile(
      NodePath.join(ctx.agentsDir, 'packages', 'pkg-a', 'examples', 'demo'),
    )
    const outsideAgentsDir = await writeLockFile(NodePath.join(ctx.projectRoot, 'outside'))
    const startDir = NodePath.join(ctx.agentsDir, 'packages', 'pkg-a', 'src')
    await Fs.mkdir(startDir, { recursive: true })

    const result = await Effect.runPromise(
      resolveAgentsDirs(true, startDir, { searchTopDir: ctx.projectRoot }).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(childAgentsDir)
    expect(result).toContain(grandchildAgentsDir)
    expect(result).not.toContain(workspaceAgentsDir)
    expect(result).not.toContain(outsideAgentsDir)
  })
})
