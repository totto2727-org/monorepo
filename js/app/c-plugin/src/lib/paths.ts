import * as Crypto from 'node:crypto'
import * as Os from 'node:os'

import { Effect, FileSystem, Predicate, String } from 'effect'

export const LOCK_FILE_NAME = 'c-plugin-lock.json'

const normalizeAbsolutePath = (path: string): string => {
  const absolute = path.startsWith('/') ? path : `${process.cwd()}/${path}`
  const parts: string[] = []
  for (const part of absolute.split('/')) {
    if (String.isEmpty(part) || part === '.') {
      continue
    }
    if (part === '..') {
      parts.pop()
      continue
    }
    parts.push(part)
  }
  return `/${parts.join('/')}`
}

const parentDirectory = (path: string): string => {
  const normalized = normalizeAbsolutePath(path)
  const index = normalized.lastIndexOf('/')
  return index <= 0 ? '/' : normalized.slice(0, index)
}

const sharedPrefixLength = (fromParts: readonly string[], toParts: readonly string[], index = 0): number =>
  Predicate.isNotNullish(fromParts[index]) && fromParts[index] === toParts[index]
    ? sharedPrefixLength(fromParts, toParts, index + 1)
    : index

const relativePath = (from: string, to: string): string => {
  const fromParts = normalizeAbsolutePath(from).split('/').filter(String.isNonEmpty)
  const toParts = normalizeAbsolutePath(to).split('/').filter(String.isNonEmpty)
  const shared = sharedPrefixLength(fromParts, toParts)
  return [...Array.from({ length: fromParts.length - shared }, () => '..'), ...toParts.slice(shared)].join('/')
}

export const getGlobalAgentsDir = (): string => `${Os.homedir()}/.agents`

export const getGlobalCacheRoot = (): string => process.env.C_PLUGIN_CACHE_ROOT ?? `${Os.homedir()}/.c-plugin/cache`

export const hashProjectRoot = (projectRoot: string): string =>
  Crypto.createHash('sha256').update(normalizeAbsolutePath(projectRoot)).digest('hex').slice(0, 12)

export const expandHomePath = (path: string): string => {
  if (path === '~') {
    return Os.homedir()
  }
  if (path.startsWith('~/')) {
    return `${Os.homedir()}/${path.slice(2)}`
  }
  return path
}

export const hasLocalPathPrefix = (spec: string): boolean => spec.startsWith('./')

export const hasParentPathPrefix = (spec: string): boolean => spec.startsWith('../')

export const hasHomePathPrefix = (spec: string): boolean => spec.startsWith('~/')

export const normalizePathSpec = (spec: string): string => {
  if (spec === './' || spec === '../' || spec === '~/') {
    return spec
  }
  return spec.length > 1 && spec.endsWith('/') ? spec.replace(/\/+$/u, '') : spec
}

export const resolveLocalPath = (spec: string, agentsRoot: string): string => {
  if (hasHomePathPrefix(spec) || spec === '~') {
    return expandHomePath(spec)
  }
  if (hasLocalPathPrefix(spec) || hasParentPathPrefix(spec)) {
    return normalizeAbsolutePath(`${agentsRoot}/${spec}`)
  }
  return spec
}

export const findAgentsRoot = (startDir: string = process.cwd()): Effect.Effect<string, Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const currentDir = normalizeAbsolutePath(startDir)
    const fs = yield* FileSystem.FileSystem

    if (yield* fs.exists(`${currentDir}/.agents`).pipe(Effect.orElseSucceed(() => false))) {
      return currentDir
    }
    const parentDir = parentDirectory(currentDir)
    if (parentDir === currentDir) {
      return yield* Effect.fail(new Error('Could not find project root with .agents directory'))
    }
    return yield* findAgentsRoot(parentDir)
  })

export const findNearestAgentsDir = (
  startDir: string = process.cwd(),
): Effect.Effect<string, Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const currentDir = normalizeAbsolutePath(startDir)
    const agentsDir = `${currentDir}/.agents`
    const lockPath = `${agentsDir}/${LOCK_FILE_NAME}`
    const fs = yield* FileSystem.FileSystem

    if (yield* fs.exists(lockPath).pipe(Effect.orElseSucceed(() => false))) {
      return agentsDir
    }
    const parentDir = parentDirectory(currentDir)
    if (parentDir === currentDir) {
      return yield* Effect.fail(new Error(`Could not find .agents directory with ${LOCK_FILE_NAME}`))
    }
    return yield* findNearestAgentsDir(parentDir)
  })

export const toRelativeLocalPath = (absPath: string, agentsRoot: string): string =>
  `./${relativePath(agentsRoot, absPath)}`

export const getCacheDir = (projectRoot: string): string => `${getGlobalCacheRoot()}/${hashProjectRoot(projectRoot)}`

export const getSkillsDir = (agentsDir: string): string => `${agentsDir}/skills`

export const getLockFilePath = (agentsDir: string): string => `${agentsDir}/${LOCK_FILE_NAME}`

export const getGitIgnorePath = (agentsDir: string): string => `${agentsDir}/.gitignore`

export const getRepoCacheDir = (projectRoot: string, source: string): string => `${getCacheDir(projectRoot)}/${source}`

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
