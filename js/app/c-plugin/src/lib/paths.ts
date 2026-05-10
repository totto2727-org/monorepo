import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Predicate, String } from 'effect'

export const getAgentsDir = (global: boolean): string =>
  global ? NodePath.join(Os.homedir(), '.agents') : NodePath.join(process.cwd(), '.agents')

export const expandHomePath = (path: string): string => {
  if (path === '~') {
    return Os.homedir()
  }
  if (path.startsWith('~/')) {
    return NodePath.join(Os.homedir(), path.slice(2))
  }
  return path
}

export const getCacheDir = (agentsDir: string): string => NodePath.join(agentsDir, '.cache')

export const getSkillsDir = (agentsDir: string): string => NodePath.join(agentsDir, 'skills')

export const getLockFilePath = (agentsDir: string): string => NodePath.join(agentsDir, 'skills-lock.json')

export const getGitIgnorePath = (agentsDir: string): string => NodePath.join(agentsDir, '.gitignore')

export const getRepoCacheDir = (agentsDir: string, source: string): string =>
  NodePath.join(getCacheDir(agentsDir), source)

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
