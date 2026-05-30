import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { describe, expect, test } from 'vite-plus/test'

import {
  expandHomePath,
  findAgentsRoot,
  findNearestAgentsDir,
  LOCK_FILE_NAME,
  getGitHubCloneUrl,
  isHomePath,
  isLocalPath,
  isParentPath,
  normalizePathSpec,
  parseRepoSource,
  resolveLocalPath,
  toRelativeLocalPath,
} from './paths.ts'

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

describe('isLocalPath', () => {
  test('accepts "./..." paths', () => {
    expect(isLocalPath('./foo')).toBe(true)
    expect(isLocalPath('./foo/bar')).toBe(true)
  })

  test('rejects non-local paths', () => {
    expect(isLocalPath('~/foo')).toBe(false)
    expect(isLocalPath('../up')).toBe(false)
    expect(isLocalPath('/abs/path')).toBe(false)
    expect(isLocalPath('foo/bar')).toBe(false)
    expect(isLocalPath('~')).toBe(false)
  })
})

describe('isParentPath', () => {
  test('accepts "../..." paths', () => {
    expect(isParentPath('../foo')).toBe(true)
    expect(isParentPath('../../bar')).toBe(true)
  })

  test('rejects non-parent paths', () => {
    expect(isParentPath('./foo')).toBe(false)
    expect(isParentPath('~/foo')).toBe(false)
    expect(isParentPath('/abs/path')).toBe(false)
  })
})

describe('isHomePath', () => {
  test('accepts "~/..." paths', () => {
    expect(isHomePath('~/foo')).toBe(true)
    expect(isHomePath('~/foo/bar')).toBe(true)
  })

  test('rejects non-home paths', () => {
    expect(isHomePath('./foo')).toBe(false)
    expect(isHomePath('../up')).toBe(false)
    expect(isHomePath('/abs/path')).toBe(false)
    expect(isHomePath('~')).toBe(false)
  })
})

describe('normalizePathSpec', () => {
  test('strips trailing slash', () => {
    expect(normalizePathSpec('./foo/')).toBe('./foo')
    expect(normalizePathSpec('~/bar/')).toBe('~/bar')
    expect(normalizePathSpec('../baz/')).toBe('../baz')
  })

  test('strips multiple trailing slashes', () => {
    expect(normalizePathSpec('./foo///')).toBe('./foo')
  })

  test('leaves paths without trailing slash unchanged', () => {
    expect(normalizePathSpec('./foo')).toBe('./foo')
    expect(normalizePathSpec('~/bar')).toBe('~/bar')
  })

  test('preserves single "/" root', () => {
    expect(normalizePathSpec('/')).toBe('/')
  })

  test('preserves prefix-only specs that mean "current/parent/home dir"', () => {
    expect(normalizePathSpec('./')).toBe('./')
    expect(normalizePathSpec('../')).toBe('../')
    expect(normalizePathSpec('~/')).toBe('~/')
  })
})

describe('resolveLocalPath', () => {
  test('resolves home-based paths', () => {
    expect(resolveLocalPath('~/foo', '/root')).toBe(NodePath.join(Os.homedir(), 'foo'))
  })

  test('resolves dot-slash paths against agents root', () => {
    expect(resolveLocalPath('./foo', '/proj')).toBe('/proj/foo')
  })
})

describe('findAgentsRoot', () => {
  test('finds nearest parent containing .agents', async () => {
    const root = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-agents-root-'))
    const nested = NodePath.join(root, 'a', 'b', 'c')
    await Fs.mkdir(NodePath.join(root, '.agents'), { recursive: true })
    await Fs.mkdir(nested, { recursive: true })

    await expect(findAgentsRoot(nested)).resolves.toBe(root)
  })

  test('throws when no .agents directory exists', async () => {
    const root = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-no-agents-root-'))
    const nested = NodePath.join(root, 'a', 'b')
    await Fs.mkdir(nested, { recursive: true })

    await expect(findAgentsRoot(nested)).rejects.toThrow('Could not find project root with .agents directory')
  })
})

describe('findNearestAgentsDir', () => {
  test('finds nearest parent .agents with lock file', async () => {
    const root = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-agents-dir-'))
    const agentsDir = NodePath.join(root, '.agents')
    await Fs.mkdir(agentsDir, { recursive: true })
    await Fs.writeFile(NodePath.join(agentsDir, LOCK_FILE_NAME), '{}', 'utf-8')
    const nested = NodePath.join(root, 'a', 'b', 'c')
    await Fs.mkdir(nested, { recursive: true })

    await expect(findNearestAgentsDir(nested)).resolves.toBe(agentsDir)
  })

  test('finds .agents in current directory', async () => {
    const root = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-agents-dir-'))
    const agentsDir = NodePath.join(root, '.agents')
    await Fs.mkdir(agentsDir, { recursive: true })
    await Fs.writeFile(NodePath.join(agentsDir, LOCK_FILE_NAME), '{}', 'utf-8')

    await expect(findNearestAgentsDir(root)).resolves.toBe(agentsDir)
  })

  test('throws when no .agents with lock file exists', async () => {
    const root = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-no-agents-dir-'))
    const nested = NodePath.join(root, 'a', 'b')
    await Fs.mkdir(nested, { recursive: true })

    await expect(findNearestAgentsDir(nested)).rejects.toThrow(
      `Could not find .agents directory with ${LOCK_FILE_NAME}`,
    )
  })
})

describe('toRelativeLocalPath', () => {
  test('converts absolute path to ./relative from agents root', () => {
    expect(toRelativeLocalPath('/proj/packages/foo', '/proj')).toBe('./packages/foo')
  })

  test('handles same directory', () => {
    expect(toRelativeLocalPath('/proj', '/proj')).toBe('./')
  })

  test('handles nested paths', () => {
    expect(toRelativeLocalPath('/proj/a/b/c', '/proj')).toBe('./a/b/c')
  })
})
