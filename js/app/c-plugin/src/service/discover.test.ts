import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { setupTestContext } from './_test-helper.ts'
import { collectAgentsDirs } from './discover.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

// ctx.agentsDir is used as the project root (workspace dir)
beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

const writeLockFile = async (agentsDir: string): Promise<void> => {
  await Fs.mkdir(agentsDir, { recursive: true })
  await Fs.writeFile(NodePath.join(agentsDir, 'skills-lock.json'), '{}', 'utf-8')
}

describe('collectAgentsDirs', () => {
  test('finds .agents in the start directory', async () => {
    const agentsDir = NodePath.join(ctx.agentsDir, '.agents')
    await writeLockFile(agentsDir)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir))
    expect(result).toContain(agentsDir)
  })

  test('finds .agents in subdirectories', async () => {
    const subDir = NodePath.join(ctx.agentsDir, 'packages', 'pkg-a')
    const subAgentsDir = NodePath.join(subDir, '.agents')
    await writeLockFile(subAgentsDir)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir))
    expect(result).toContain(subAgentsDir)
  })

  test('finds multiple .agents dirs in sibling directories', async () => {
    const agentsDirA = NodePath.join(ctx.agentsDir, 'packages', 'pkg-a', '.agents')
    const agentsDirB = NodePath.join(ctx.agentsDir, 'packages', 'pkg-b', '.agents')
    await writeLockFile(agentsDirA)
    await writeLockFile(agentsDirB)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir))
    expect(result).toContain(agentsDirA)
    expect(result).toContain(agentsDirB)
  })

  test('does not recurse into .agents itself', async () => {
    const agentsDir = NodePath.join(ctx.agentsDir, '.agents')
    await writeLockFile(agentsDir)
    // place a nested .agents inside .agents/.cache to ensure it is not found
    const nested = NodePath.join(agentsDir, '.cache', 'repo', '.agents')
    await writeLockFile(nested)

    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir))
    expect(result).toContain(agentsDir)
    expect(result).not.toContain(nested)
  })

  test('returns empty array when no .agents found', async () => {
    const result = await Effect.runPromise(collectAgentsDirs(ctx.agentsDir))
    expect(result).toStrictEqual([])
  })
})
