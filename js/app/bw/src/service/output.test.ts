import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import { printJson, printText, writeFile, writeText } from './output.ts'

let tmpDir: string

beforeEach(async () => {
  tmpDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'bw-output-test-'))
})

afterEach(async () => {
  await Fs.rm(tmpDir, { force: true, recursive: true })
  vi.restoreAllMocks()
})

describe('writeFile', () => {
  test('writes binary data to file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.bin')
    const data = new Uint8Array([1, 2, 3, 4, 5])

    await Effect.runPromise(writeFile(filePath, data))

    const written = await Fs.readFile(filePath)
    expect(new Uint8Array(written)).toStrictEqual(data)
  })

  test('overwrites existing file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.bin')
    await Fs.writeFile(filePath, Buffer.from([0, 0, 0]))

    const data = new Uint8Array([10, 20])
    await Effect.runPromise(writeFile(filePath, data))

    const written = await Fs.readFile(filePath)
    expect(new Uint8Array(written)).toStrictEqual(data)
  })
})

describe('writeText', () => {
  test('writes text to file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.txt')

    await Effect.runPromise(writeText(filePath, 'hello world'))

    const content = await Fs.readFile(filePath, 'utf-8')
    expect(content).toBe('hello world')
  })

  test('overwrites existing file', async () => {
    const filePath = NodePath.join(tmpDir, 'output.txt')
    await Fs.writeFile(filePath, 'old content', 'utf-8')

    await Effect.runPromise(writeText(filePath, 'new content'))

    const content = await Fs.readFile(filePath, 'utf-8')
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
