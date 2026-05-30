import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, describe, expect, test } from 'vite-plus/test'

import { getLockFilePath } from '#@/lib/paths.ts'
import { emptyLockFile } from '#@/schema/lock-file.ts'

import { initCommand, initLockFile } from './init.ts'

const tmpDirs: string[] = []

afterEach(async () => {
  await Promise.all(tmpDirs.splice(0).map((dir) => Fs.rm(dir, { force: true, recursive: true })))
})

const mkTmp = async (): Promise<string> => {
  const dir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-init-test-'))
  tmpDirs.push(dir)
  return dir
}

describe('initCommand', () => {
  test('is importable', () => {
    expect(initCommand).toBeDefined()
  })
})

describe('initLockFile', () => {
  test('creates only an empty lock file under .agents in the target directory', async () => {
    const projectRoot = await mkTmp()
    const lockPath = getLockFilePath(NodePath.join(projectRoot, '.agents'))

    await Effect.runPromise(initLockFile(projectRoot))

    await expect(Fs.readFile(lockPath, 'utf-8')).resolves.toBe(`${JSON.stringify(emptyLockFile, null, '\t')}\n`)
    await expect(Fs.readdir(NodePath.join(projectRoot, '.agents'))).resolves.toStrictEqual(['c-plugin-lock.json'])
  })

  test('does not overwrite an existing lock file', async () => {
    const projectRoot = await mkTmp()
    const lockPath = getLockFilePath(NodePath.join(projectRoot, '.agents'))
    await Fs.mkdir(NodePath.dirname(lockPath), { recursive: true })
    await Fs.writeFile(lockPath, '{"version":1,"repositories":[],"skillDirs":["/keep"]}\n', 'utf-8')

    await expect(Effect.runPromise(initLockFile(projectRoot))).rejects.toThrow()
    await expect(Fs.readFile(lockPath, 'utf-8')).resolves.toBe(
      '{"version":1,"repositories":[],"skillDirs":["/keep"]}\n',
    )
  })
})
