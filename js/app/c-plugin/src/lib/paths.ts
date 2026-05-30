import * as Crypto from 'node:crypto'
import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Predicate, String } from 'effect'

export const getGlobalAgentsDir = (): string => NodePath.join(Os.homedir(), '.agents')

export const getGlobalCacheRoot = (): string =>
  process.env.C_PLUGIN_CACHE_ROOT ?? NodePath.join(Os.homedir(), '.c-plugin', 'cache')

export const hashProjectRoot = (projectRoot: string): string =>
  Crypto.createHash('sha256').update(NodePath.resolve(projectRoot)).digest('hex').slice(0, 12)

export const expandHomePath = (path: string): string => {
  if (path === '~') {
    return Os.homedir()
  }
  if (path.startsWith('~/')) {
    return NodePath.join(Os.homedir(), path.slice(2))
  }
  return path
}

export const isLocalPath = (spec: string): boolean => spec.startsWith('./')

export const isParentPath = (spec: string): boolean => spec.startsWith('../')

export const isHomePath = (spec: string): boolean => spec.startsWith('~/')

export const normalizePathSpec = (spec: string): string => {
  if (spec === './' || spec === '../' || spec === '~/') {
    return spec
  }
  return spec.length > 1 && spec.endsWith('/') ? spec.replace(/\/+$/u, '') : spec
}

export const resolveLocalPath = (spec: string, agentsRoot: string): string => {
  if (isHomePath(spec) || spec === '~') {
    return expandHomePath(spec)
  }
  if (isLocalPath(spec) || isParentPath(spec)) {
    return NodePath.resolve(agentsRoot, spec)
  }
  return spec
}

export const findAgentsRoot = async (startDir: string = process.cwd()): Promise<string> => {
  const currentDir = NodePath.resolve(startDir)

  try {
    await Fs.access(NodePath.join(currentDir, '.agents'))
    return currentDir
  } catch {
    const parentDir = NodePath.dirname(currentDir)
    if (parentDir === currentDir) {
      throw new Error('Could not find project root with .agents directory')
    }
    return await findAgentsRoot(parentDir)
  }
}

export const findNearestAgentsDir = async (startDir: string = process.cwd()): Promise<string> => {
  const currentDir = NodePath.resolve(startDir)
  const agentsDir = NodePath.join(currentDir, '.agents')
  const lockPath = NodePath.join(agentsDir, 'skills-lock.json')

  try {
    await Fs.access(lockPath)
    return agentsDir
  } catch {
    const parentDir = NodePath.dirname(currentDir)
    if (parentDir === currentDir) {
      throw new Error('Could not find .agents directory with skills-lock.json')
    }
    return await findNearestAgentsDir(parentDir)
  }
}

export const toRelativeLocalPath = (absPath: string, agentsRoot: string): string =>
  `./${NodePath.relative(agentsRoot, absPath)}`

export const getCacheDir = (projectRoot: string): string =>
  NodePath.join(getGlobalCacheRoot(), hashProjectRoot(projectRoot))

export const getSkillsDir = (agentsDir: string): string => NodePath.join(agentsDir, 'skills')

export const getLockFilePath = (agentsDir: string): string => NodePath.join(agentsDir, 'skills-lock.json')

export const getGitIgnorePath = (agentsDir: string): string => NodePath.join(agentsDir, '.gitignore')

export const getRepoCacheDir = (projectRoot: string, source: string): string =>
  NodePath.join(getCacheDir(projectRoot), source)

export const parseRepoSource = (repo: string): { owner: string; name: string } => {
  const parts = repo.split('/')
  if (
    parts.length !== 2 ||
    Predicate.isNullish(parts[0]) ||
    String.isEmpty(parts[0]) ||
    Predicate.isNullish(parts[1]) ||
    String.isEmpty(parts[1])
  ) {
    throw new Error(`Invalid repository format: ${repo}. Expected "owner/repo".`)
  }
  return { name: parts[1], owner: parts[0] }
}

export const getGitHubCloneUrl = (source: string): string => `https://github.com/${source}.git`
