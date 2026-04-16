import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect, Exit } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { setupTestContext } from './_test-helper.ts'
import { syncMarketplace } from './marketplace-sync.ts'

let ctx: Awaited<ReturnType<typeof setupTestContext>>

beforeEach(async () => {
  ctx = await setupTestContext()
})

afterEach(async () => {
  await ctx.cleanup()
})

const writeClaudeMarketplace = async (repoDir: string, marketplace: object): Promise<void> => {
  const dir = NodePath.join(repoDir, '.claude-plugin')
  await Fs.mkdir(dir, { recursive: true })
  await Fs.writeFile(NodePath.join(dir, 'marketplace.json'), JSON.stringify(marketplace, null, 2), 'utf-8')
}

const writeCodexMarketplace = async (repoDir: string, marketplace: object): Promise<void> => {
  const dir = NodePath.join(repoDir, '.agents', 'plugins')
  await Fs.mkdir(dir, { recursive: true })
  await Fs.writeFile(NodePath.join(dir, 'marketplace.json'), JSON.stringify(marketplace, null, 2), 'utf-8')
}

const readJsonFile = async (filePath: string): Promise<unknown> => {
  const text = await Fs.readFile(filePath, 'utf-8')
  return JSON.parse(text)
}

describe('syncMarketplace', () => {
  describe('claude base', () => {
    test('generates codex and cursor marketplace from claude base', async () => {
      const repoDir = NodePath.join(ctx.agentsDir, 'repo')
      await Fs.mkdir(repoDir, { recursive: true })

      await writeClaudeMarketplace(repoDir, {
        name: 'test-marketplace',
        plugins: [
          { description: 'desc-a', name: 'plugin-a', source: 'plugins/plugin-a' },
          { description: 'desc-b', name: 'plugin-b', source: 'plugins/plugin-b' },
        ],
      })

      await Effect.runPromise(syncMarketplace(repoDir, 'claude'))

      // Codex marketplace
      const codexMarketplace = await readJsonFile(NodePath.join(repoDir, '.agents', 'plugins', 'marketplace.json'))
      expect(codexMarketplace).toStrictEqual({
        name: 'test-marketplace',
        plugins: [
          {
            category: 'Productivity',
            name: 'plugin-a',
            policy: { authentication: 'ON_INSTALL', installation: 'AVAILABLE' },
            source: { path: './plugins/plugin-a', source: 'local' },
          },
          {
            category: 'Productivity',
            name: 'plugin-b',
            policy: { authentication: 'ON_INSTALL', installation: 'AVAILABLE' },
            source: { path: './plugins/plugin-b', source: 'local' },
          },
        ],
      })

      // Cursor marketplace
      const cursorMarketplace = await readJsonFile(NodePath.join(repoDir, '.cursor-plugin', 'marketplace.json'))
      expect(cursorMarketplace).toStrictEqual({
        name: 'test-marketplace',
        plugins: [
          { description: 'desc-a', name: 'plugin-a', source: 'plugins/plugin-a' },
          { description: 'desc-b', name: 'plugin-b', source: 'plugins/plugin-b' },
        ],
      })
    })

    test('syncs plugin.json for each plugin', async () => {
      const repoDir = NodePath.join(ctx.agentsDir, 'repo')
      await Fs.mkdir(repoDir, { recursive: true })

      await writeClaudeMarketplace(repoDir, {
        name: 'test',
        plugins: [{ name: 'p', source: 'plugins/p' }],
      })

      // Write source plugin.json
      const pluginDir = NodePath.join(repoDir, 'plugins', 'p', '.claude-plugin')
      await Fs.mkdir(pluginDir, { recursive: true })
      await Fs.writeFile(NodePath.join(pluginDir, 'plugin.json'), JSON.stringify({ key: 'value' }), 'utf-8')

      await Effect.runPromise(syncMarketplace(repoDir, 'claude'))

      // Codex plugin.json should exist
      const codexPluginJson = await readJsonFile(NodePath.join(repoDir, 'plugins', 'p', '.codex-plugin', 'plugin.json'))
      expect(codexPluginJson).toStrictEqual({ key: 'value' })

      // Cursor plugin.json should exist
      const cursorPluginJson = await readJsonFile(
        NodePath.join(repoDir, 'plugins', 'p', '.cursor-plugin', 'plugin.json'),
      )
      expect(cursorPluginJson).toStrictEqual({ key: 'value' })
    })

    test('skips plugin.json sync when source plugin.json does not exist', async () => {
      const repoDir = NodePath.join(ctx.agentsDir, 'repo')
      await Fs.mkdir(repoDir, { recursive: true })

      await writeClaudeMarketplace(repoDir, {
        name: 'test',
        plugins: [{ name: 'p', source: 'plugins/p' }],
      })

      await Effect.runPromise(syncMarketplace(repoDir, 'claude'))

      // No codex plugin.json should be created
      await expect(Fs.access(NodePath.join(repoDir, 'plugins', 'p', '.codex-plugin', 'plugin.json'))).rejects.toThrow()
    })
  })

  describe('codex base', () => {
    test('generates claude and cursor marketplace from codex base', async () => {
      const repoDir = NodePath.join(ctx.agentsDir, 'repo')
      await Fs.mkdir(repoDir, { recursive: true })

      await writeCodexMarketplace(repoDir, {
        name: 'codex-marketplace',
        plugins: [
          {
            name: 'plugin-a',
            source: { path: './plugins/plugin-a', source: 'local' },
          },
        ],
      })

      await Effect.runPromise(syncMarketplace(repoDir, 'codex'))

      // Claude marketplace
      const claudeMarketplace = await readJsonFile(NodePath.join(repoDir, '.claude-plugin', 'marketplace.json'))
      expect(claudeMarketplace).toStrictEqual({
        name: 'codex-marketplace',
        plugins: [{ name: 'plugin-a', source: 'plugins/plugin-a' }],
      })
    })
  })

  test('fails when base marketplace.json is missing', async () => {
    const repoDir = NodePath.join(ctx.agentsDir, 'empty-repo')
    await Fs.mkdir(repoDir, { recursive: true })

    const exit = await Effect.runPromiseExit(syncMarketplace(repoDir, 'claude'))
    expect(Exit.isFailure(exit)).toBe(true)
  })
})
