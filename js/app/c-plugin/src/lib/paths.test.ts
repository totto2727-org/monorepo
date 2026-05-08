import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { describe, expect, test } from 'vite-plus/test'

import { expandHomePath, getGitHubCloneUrl, parseRepoSource } from './paths.ts'

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

describe('expandHomePath', () => {
  test('expands lone "~" to home directory', () => {
    expect(expandHomePath('~')).toBe(Os.homedir())
  })

  test('expands "~/" prefix to home directory', () => {
    expect(expandHomePath('~/foo/bar')).toBe(NodePath.join(Os.homedir(), 'foo', 'bar'))
  })

  test('returns absolute path unchanged', () => {
    expect(expandHomePath('/abs/path')).toBe('/abs/path')
  })

  test('returns relative path unchanged', () => {
    expect(expandHomePath('relative/path')).toBe('relative/path')
  })

  test('does not expand "~user" form', () => {
    expect(expandHomePath('~other/foo')).toBe('~other/foo')
  })

  test('returns empty string unchanged', () => {
    expect(expandHomePath('')).toBe('')
  })
})
