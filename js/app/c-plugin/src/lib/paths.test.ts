import { describe, expect, test } from 'vite-plus/test'

import { getGitHubCloneUrl, parseRepoSource } from './paths.ts'

describe('parseRepoSource', () => {
  test('parses valid owner/repo format', () => {
    const result = parseRepoSource('owner/repo')
    expect(result).toStrictEqual({ name: 'repo', owner: 'owner' })
  })

  test('throws for invalid format without slash', () => {
    expect(() => parseRepoSource('invalid')).toThrow('Invalid repository format')
  })

  test('throws for empty owner', () => {
    expect(() => parseRepoSource('/repo')).toThrow('Invalid repository format')
  })

  test('throws for empty repo name', () => {
    expect(() => parseRepoSource('owner/')).toThrow('Invalid repository format')
  })

  test('throws for too many slashes', () => {
    expect(() => parseRepoSource('a/b/c')).toThrow('Invalid repository format')
  })
})

describe('getGitHubCloneUrl', () => {
  test('returns https clone URL', () => {
    expect(getGitHubCloneUrl('owner/repo')).toBe('https://github.com/owner/repo.git')
  })
})
