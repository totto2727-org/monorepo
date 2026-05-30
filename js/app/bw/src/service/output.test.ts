import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { NodeServices } from '@effect/platform-node'
import { Effect, FileSystem } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { printJson, printText, writeFile, writeText } from './output.ts'

let tmpDir: string

const runWithNodeServices = <A, E>(effect: Effect.Effect<A, E, FileSystem.FileSystem>) =>
  Effect.runPromise(effect.pipe(Effect.provide(NodeServices.layer)))

const fsEffect = <A, E>(effect: Effect.Effect<A, E, FileSystem.FileSystem>) => runWithNodeServices(effect)

const makeTempDir = (prefix: string): Promise<string> =>
  fsEffect(
    Effect.gen(function* () {
      const fs = yield* FileSystem.FileSystem
      return yield* fs.makeTempDirectory({ directory: Os.tmpdir(), prefix })
    }),
  )

beforeEach(async () => {
  tmpDir = await makeTempDir('bw-output-test-')
})

afterEach(async () => {
  await fsEffect(
    Effect.gen(function* () {
      const fs = yield* FileSystem.FileSystem
      yield* fs.remove(tmpDir, { force: true, recursive: true })
    }),
  )
  vi.restoreAllMocks()
})

describe('writeFile', () => {
  test('writes binary data to file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.bin')
    const data = new Uint8Array([1, 2, 3, 4, 5])

    await runWithNodeServices(writeFile(filePath, data))

    const written = await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        return yield* fs.readFile(filePath)
      }),
    )
    expect(new Uint8Array(written)).toStrictEqual(data)
  })

  test('overwrites existing file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.bin')
    await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        yield* fs.writeFile(filePath, new Uint8Array([0, 0, 0]))
      }),
    )

    const data = new Uint8Array([10, 20])
    await runWithNodeServices(writeFile(filePath, data))

    const written = await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        return yield* fs.readFile(filePath)
      }),
    )
    expect(new Uint8Array(written)).toStrictEqual(data)
  })
})

describe('writeText', () => {
  test('writes text to file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.txt')

    await runWithNodeServices(writeText(filePath, 'hello world'))

    const content = await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        return yield* fs.readFileString(filePath)
      }),
    )
    expect(content).toBe('hello world')
  })

  test('overwrites existing file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.txt')
    await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        yield* fs.writeFileString(filePath, 'old content')
      }),
    )

    await runWithNodeServices(writeText(filePath, 'new content'))

    const content = await fsEffect(
      Effect.gen(function* () {
        const fs = yield* FileSystem.FileSystem
        return yield* fs.readFileString(filePath)
      }),
    )
    expect(content).toBe('new content')
  })
})

describe('printJson', () => {
  test('prints JSON formatted output', async () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})

    await Effect.runPromise(printJson({ key: 'value' }))

    expect(spy).toHaveBeenCalledWith(JSON.stringify({ key: 'value' }, null, 2))
  })
})

describe('printText', () => {
  test('prints text output', async () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})

    await Effect.runPromise(printText('hello'))

    expect(spy).toHaveBeenCalledWith('hello')
  })
})
