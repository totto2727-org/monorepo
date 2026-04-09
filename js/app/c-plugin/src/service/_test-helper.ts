import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { getCacheDir, getLockFilePath, getRepoCacheDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import type { Marketplace } from '#@/schema/marketplace.ts'

export const setupTestContext = async (): Promise<{ agentsDir: string; cleanup: () => Promise<void> }> => {
  const agentsDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-test-'))
  return {
    agentsDir,
    cleanup: () => Fs.rm(agentsDir, { force: true, recursive: true }),
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
  agentsDir: string,
  source: string,
  options: FakeRepoFixtureOptions,
): Promise<string> => {
  const repoDir = getRepoCacheDir(agentsDir, source)

  const marketplace: Marketplace = {
    name: options.marketplaceName ?? 'test-marketplace',
    plugins: options.plugins.map((p) => ({
      name: p.name,
      source: p.source,
    })),
  }

  const marketplaceDir = NodePath.join(repoDir, '.claude-plugin')
  await Fs.mkdir(marketplaceDir, { recursive: true })
  await Fs.writeFile(NodePath.join(marketplaceDir, 'marketplace.json'), JSON.stringify(marketplace, null, '\t'), 'utf8')

  for (const plugin of options.plugins) {
    for (const skill of plugin.skills) {
      const skillDir = NodePath.join(repoDir, plugin.source, 'skills', skill)
      await Fs.mkdir(skillDir, { recursive: true })
      await Fs.writeFile(NodePath.join(skillDir, 'SKILL.md'), `# ${skill}\n`, 'utf8')
    }
  }

  return repoDir
}

export const writeLockFile = async (agentsDir: string, lockFile: LockFile): Promise<void> => {
  const path = getLockFilePath(agentsDir)
  await Fs.mkdir(NodePath.dirname(path), { recursive: true })
  await Fs.writeFile(path, `${JSON.stringify(lockFile, null, '\t')}\n`, 'utf8')
}

export const ensureAgentsDirs = async (agentsDir: string): Promise<void> => {
  await Fs.mkdir(getCacheDir(agentsDir), { recursive: true })
  await Fs.mkdir(NodePath.join(agentsDir, 'skills'), { recursive: true })
}
