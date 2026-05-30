import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Predicate } from 'effect'

import { getCacheDir, getLockFilePath, getRepoCacheDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import type { Marketplace } from '#@/schema/marketplace.ts'

export interface TestContext {
  readonly projectRoot: string
  readonly agentsDir: string
  readonly cleanup: () => Promise<void>
}

export const setupTestContext = async (): Promise<TestContext> => {
  const projectRoot = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-test-'))
  const agentsDir = NodePath.join(projectRoot, '.agents')
  await Fs.mkdir(agentsDir, { recursive: true })

  const cacheRoot = NodePath.join(projectRoot, '.c-plugin-cache-test')
  const previousCacheRoot = process.env.C_PLUGIN_CACHE_ROOT
  process.env.C_PLUGIN_CACHE_ROOT = cacheRoot

  return {
    agentsDir,
    cleanup: async () => {
      if (Predicate.isNullish(previousCacheRoot)) {
        delete process.env.C_PLUGIN_CACHE_ROOT
      } else {
        process.env.C_PLUGIN_CACHE_ROOT = previousCacheRoot
      }
      await Fs.rm(projectRoot, { force: true, recursive: true })
    },
    projectRoot,
  }
}

export interface FakePluginOptions {
  readonly name: string
  readonly source: string
  readonly skills: readonly string[]
}

export interface FakeRepoFixtureOptions {
  readonly marketplaceName?: string
  readonly plugins: readonly FakePluginOptions[]
}

export const buildFakeRepoFixture = async (
  projectRoot: string,
  source: string,
  options: FakeRepoFixtureOptions,
): Promise<string> => {
  const repoDir = getRepoCacheDir(projectRoot, source)

  const marketplace: Marketplace = {
    name: options.marketplaceName ?? 'test-marketplace',
    plugins: options.plugins.map((p) => ({
      name: p.name,
      source: p.source,
    })),
  }

  const marketplaceDir = NodePath.join(repoDir, '.claude-plugin')
  await Fs.mkdir(marketplaceDir, { recursive: true })
  await Fs.writeFile(
    NodePath.join(marketplaceDir, 'marketplace.json'),
    JSON.stringify(marketplace, null, '\t'),
    'utf-8',
  )

  for (const plugin of options.plugins) {
    for (const skill of plugin.skills) {
      const skillDir = NodePath.join(repoDir, plugin.source, 'skills', skill)
      await Fs.mkdir(skillDir, { recursive: true })
      await Fs.writeFile(NodePath.join(skillDir, 'SKILL.md'), `# ${skill}\n`, 'utf-8')
    }
  }

  return repoDir
}

export const writeLockFile = async (agentsDir: string, lockFile: LockFile): Promise<void> => {
  const path = getLockFilePath(agentsDir)
  await Fs.mkdir(NodePath.dirname(path), { recursive: true })
  await Fs.writeFile(path, `${JSON.stringify(lockFile, null, '\t')}\n`, 'utf-8')
}

export const ensureAgentsDirs = async (agentsDir: string, projectRoot: string): Promise<void> => {
  await Fs.mkdir(getCacheDir(projectRoot), { recursive: true })
  await Fs.mkdir(NodePath.join(agentsDir, 'skills'), { recursive: true })
}
