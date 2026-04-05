import * as Os from 'node:os'
import * as NodePath from 'node:path'

export const getAgentsDir = (global: boolean): string =>
  global ? NodePath.join(Os.homedir(), '.agents') : NodePath.join(process.cwd(), '.agents')

export const getCacheDir = (agentsDir: string): string => NodePath.join(agentsDir, '.cache')

export const getSkillsDir = (agentsDir: string): string => NodePath.join(agentsDir, 'skills')

export const getLockFilePath = (agentsDir: string): string => NodePath.join(agentsDir, 'skills-lock.json')

export const getRepoCacheDir = (agentsDir: string, source: string): string =>
  NodePath.join(getCacheDir(agentsDir), source)

export const parseRepoSource = (repo: string): { owner: string; name: string } => {
  const parts = repo.split('/')
  if (parts.length !== 2 || parts[0] === undefined || parts[0] === '' || parts[1] === undefined || parts[1] === '') {
    throw new Error(`Invalid repository format: ${repo}. Expected "owner/repo".`)
  }
  return { name: parts[1], owner: parts[0] }
}

export const getGitHubCloneUrl = (source: string): string => `https://github.com/${source}.git`
