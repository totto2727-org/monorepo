import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { collectRecursiveTargetFiles, findHomeTargetFile, findParentTargetFile } from './index.ts'

const TARGET_FILE_NAME = 'target.lock'

let rootDir: string

beforeEach(async () => {
  rootDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'target-file-discovery-'))
})

afterEach(async () => {
  await Fs.rm(rootDir, { force: true, recursive: true })
})

const writeTargetFile = async (dir: string): Promise<string> => {
  await Fs.mkdir(dir, { recursive: true })
  const filePath = NodePath.join(dir, TARGET_FILE_NAME)
  await Fs.writeFile(filePath, '{}', 'utf-8')
  return filePath
}

const writeGitIgnore = async (dir: string, content: string): Promise<void> => {
  await Fs.mkdir(dir, { recursive: true })
  await Fs.writeFile(NodePath.join(dir, '.gitignore'), content, 'utf-8')
}

describe('findHomeTargetFile', () => {
  test('finds the target file directly under the home-level directory', async () => {
    const homeDir = NodePath.join(rootDir, 'home')
    const homeTarget = await writeTargetFile(homeDir)

    const result = await Effect.runPromise(
      findHomeTargetFile(homeDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toBe(homeTarget)
  })

  test('fails when no home-level target file exists', async () => {
    const homeDir = NodePath.join(rootDir, 'home')
    await Fs.mkdir(homeDir, { recursive: true })

    await expect(
      Effect.runPromise(findHomeTargetFile(homeDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer))),
    ).rejects.toThrow(`Could not find home-level file: ${TARGET_FILE_NAME}`)
  })
})

describe('findParentTargetFile', () => {
  test('finds the target file in the start directory', async () => {
    const startDir = NodePath.join(rootDir, 'packages', 'pkg-a')
    const startTarget = await writeTargetFile(startDir)

    const result = await Effect.runPromise(
      findParentTargetFile(TARGET_FILE_NAME, rootDir, startDir).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toBe(startTarget)
  })

  test('finds the nearest ancestor target file from a nested directory', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    const packageDir = NodePath.join(rootDir, 'packages', 'pkg-a')
    const packageTarget = await writeTargetFile(packageDir)
    const startDir = NodePath.join(packageDir, 'src', 'feature')
    await Fs.mkdir(startDir, { recursive: true })

    const result = await Effect.runPromise(
      findParentTargetFile(TARGET_FILE_NAME, rootDir, startDir).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toBe(packageTarget)
    expect(result).not.toBe(rootTarget)
  })

  test('fails when no ancestor target file exists', async () => {
    const startDir = NodePath.join(rootDir, 'packages', 'pkg-a')
    await Fs.mkdir(startDir, { recursive: true })

    await expect(
      Effect.runPromise(
        findParentTargetFile(TARGET_FILE_NAME, rootDir, startDir).pipe(Effect.provide(NodeServices.layer)),
      ),
    ).rejects.toThrow(`Could not find ancestor file: ${TARGET_FILE_NAME}`)
  })

  test('accepts a target file at the top boundary', async () => {
    const topTarget = await writeTargetFile(rootDir)
    const startDir = NodePath.join(rootDir, 'packages', 'pkg-a')
    await Fs.mkdir(startDir, { recursive: true })

    const result = await Effect.runPromise(
      findParentTargetFile(TARGET_FILE_NAME, rootDir, startDir).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toBe(topTarget)
  })

  test('does not search above the top boundary', async () => {
    const outerDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'target-file-discovery-outer-'))
    try {
      const topDir = NodePath.join(outerDir, 'top')
      const startDir = NodePath.join(topDir, 'packages', 'pkg-a')
      await writeTargetFile(outerDir)
      await Fs.mkdir(startDir, { recursive: true })

      await expect(
        Effect.runPromise(
          findParentTargetFile(TARGET_FILE_NAME, topDir, startDir).pipe(Effect.provide(NodeServices.layer)),
        ),
      ).rejects.toThrow(`Could not find ancestor file: ${TARGET_FILE_NAME}`)
    } finally {
      await Fs.rm(outerDir, { force: true, recursive: true })
    }
  })
})

describe('collectRecursiveTargetFiles', () => {
  test('collects target files from the start directory and descendants', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    const childTarget = await writeTargetFile(NodePath.join(rootDir, 'packages', 'pkg-a'))
    const grandchildTarget = await writeTargetFile(NodePath.join(rootDir, 'packages', 'pkg-a', 'examples', 'demo'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(rootTarget)
    expect(result).toContain(childTarget)
    expect(result).toContain(grandchildTarget)
  })

  test('uses only .gitignore rules for skip decisions', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    const dotAgentsTarget = await writeTargetFile(NodePath.join(rootDir, '.agents', '.cache', 'repo'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(rootTarget)
    expect(result).toContain(dotAgentsTarget)
  })

  test('does not recurse into directories ignored by the current .gitignore', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    await writeGitIgnore(rootDir, 'ignored-packages/\n')
    const ignoredTarget = await writeTargetFile(NodePath.join(rootDir, 'ignored-packages', 'pkg-a'))
    const visibleTarget = await writeTargetFile(NodePath.join(rootDir, 'packages', 'pkg-a'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(rootTarget)
    expect(result).toContain(visibleTarget)
    expect(result).not.toContain(ignoredTarget)
  })

  test('does not recurse into directories ignored by anchored .gitignore patterns', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    await writeGitIgnore(rootDir, '/ignored-packages/\n')
    const ignoredTarget = await writeTargetFile(NodePath.join(rootDir, 'ignored-packages', 'pkg-a'))
    const visibleTarget = await writeTargetFile(NodePath.join(rootDir, 'packages', 'pkg-a'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(rootTarget)
    expect(result).toContain(visibleTarget)
    expect(result).not.toContain(ignoredTarget)
  })

  test('inherits parent .gitignore rules while scanning grandchildren', async () => {
    const rootTarget = await writeTargetFile(rootDir)
    const packageDir = NodePath.join(rootDir, 'packages', 'pkg-a')
    await writeGitIgnore(packageDir, 'examples/ignored-demo/\n')
    const packageTarget = await writeTargetFile(packageDir)
    const visibleDemoTarget = await writeTargetFile(NodePath.join(packageDir, 'examples', 'visible-demo'))
    const ignoredDemoTarget = await writeTargetFile(NodePath.join(packageDir, 'examples', 'ignored-demo'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(rootTarget)
    expect(result).toContain(packageTarget)
    expect(result).toContain(visibleDemoTarget)
    expect(result).not.toContain(ignoredDemoTarget)
  })

  test('includes target files ignored by the local .gitignore in visited directories', async () => {
    await writeGitIgnore(rootDir, TARGET_FILE_NAME)
    const ignoredRootTarget = await writeTargetFile(rootDir)
    const childTarget = await writeTargetFile(NodePath.join(rootDir, 'packages', 'pkg-a'))

    const result = await Effect.runPromise(
      collectRecursiveTargetFiles(rootDir, TARGET_FILE_NAME).pipe(Effect.provide(NodeServices.layer)),
    )

    expect(result).toContain(ignoredRootTarget)
    expect(result).toContain(childTarget)
  })
})
