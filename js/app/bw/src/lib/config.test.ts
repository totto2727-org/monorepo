import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { Effect, Exit, Option } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { applyWaitUntil, loadConfig, resolveInput } from './config.ts'

let tmpDir: string

beforeEach(async () => {
  tmpDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'bw-config-test-'))
})

afterEach(async () => {
  await Fs.rm(tmpDir, { force: true, recursive: true })
})

describe('loadConfig', () => {
  test('returns empty object when configPath is None', async () => {
    const result = await Effect.runPromise(loadConfig(Option.none()))
    expect(result).toStrictEqual({})
  })

  test('loads and parses valid JSON config file', async () => {
    const configPath = NodePath.join(tmpDir, 'config.json')
    await Fs.writeFile(configPath, JSON.stringify({ html: '<p>test</p>', url: 'https://example.com' }), 'utf-8')

    const result = await Effect.runPromise(loadConfig(Option.some(configPath)))
    expect(result).toStrictEqual({ html: '<p>test</p>', url: 'https://example.com' })
  })

  test('fails when file does not exist', async () => {
    const configPath = NodePath.join(tmpDir, 'nonexistent.json')

    const exit = await Effect.runPromiseExit(loadConfig(Option.some(configPath)))
    expect(Exit.isFailure(exit)).toBe(true)
  })

  test('fails when file contains invalid JSON', async () => {
    const configPath = NodePath.join(tmpDir, 'bad.json')
    await Fs.writeFile(configPath, '{ invalid }', 'utf-8')

    const exit = await Effect.runPromiseExit(loadConfig(Option.some(configPath)))
    expect(Exit.isFailure(exit)).toBe(true)
  })
})

describe('resolveInput', () => {
  test('resolves url from urlFlag', async () => {
    const result = await Effect.runPromise(resolveInput(Option.some('https://example.com'), Option.none(), {}))
    expect(result).toStrictEqual({ url: 'https://example.com' })
  })

  test('resolves html content from htmlFlag', async () => {
    const htmlPath = NodePath.join(tmpDir, 'page.html')
    await Fs.writeFile(htmlPath, '<h1>Hello</h1>', 'utf-8')

    const result = await Effect.runPromise(resolveInput(Option.none(), Option.some(htmlPath), {}))
    expect(result).toStrictEqual({ html: '<h1>Hello</h1>' })
  })

  test('uses config url when no flags provided and config has url', async () => {
    const result = await Effect.runPromise(
      resolveInput(Option.none(), Option.none(), { url: 'https://from-config.com' }),
    )
    expect(result).toStrictEqual({ url: 'https://from-config.com' })
  })

  test('uses config html when no flags provided and config has html', async () => {
    const result = await Effect.runPromise(resolveInput(Option.none(), Option.none(), { html: '<p>from config</p>' }))
    expect(result).toStrictEqual({ html: '<p>from config</p>' })
  })

  test('urlFlag takes priority over htmlFlag', async () => {
    const htmlPath = NodePath.join(tmpDir, 'page.html')
    await Fs.writeFile(htmlPath, '<p>html</p>', 'utf-8')

    const result = await Effect.runPromise(resolveInput(Option.some('https://example.com'), Option.some(htmlPath), {}))
    expect(result).toStrictEqual({ url: 'https://example.com' })
  })

  test('fails when no url or html is available', async () => {
    const exit = await Effect.runPromiseExit(resolveInput(Option.none(), Option.none(), {}))
    expect(Exit.isFailure(exit)).toBe(true)
  })

  test('fails when html file does not exist', async () => {
    const exit = await Effect.runPromiseExit(
      resolveInput(Option.none(), Option.some(NodePath.join(tmpDir, 'missing.html')), {}),
    )
    expect(Exit.isFailure(exit)).toBe(true)
  })

  test('merges flags with existing config', async () => {
    const result = await Effect.runPromise(
      resolveInput(Option.some('https://example.com'), Option.none(), { extra: 'value' }),
    )
    expect(result).toStrictEqual({ extra: 'value', url: 'https://example.com' })
  })
})

describe('applyWaitUntil', () => {
  test('returns body unchanged when waitUntil is None', () => {
    const body = { url: 'https://example.com' }
    const result = applyWaitUntil(body, Option.none())
    expect(result).toStrictEqual({ url: 'https://example.com' })
  })

  test('adds gotoOptions with waitUntil when None previously', () => {
    const body = { url: 'https://example.com' }
    const result = applyWaitUntil(body, Option.some('networkidle0'))
    expect(result).toStrictEqual({
      gotoOptions: { waitUntil: 'networkidle0' },
      url: 'https://example.com',
    })
  })

  test('merges with existing gotoOptions', () => {
    const body = { gotoOptions: { timeout: 5000 }, url: 'https://example.com' }
    const result = applyWaitUntil(body, Option.some('domcontentloaded'))
    expect(result).toStrictEqual({
      gotoOptions: { timeout: 5000, waitUntil: 'domcontentloaded' },
      url: 'https://example.com',
    })
  })

  test('overwrites existing gotoOptions.waitUntil', () => {
    const body = { gotoOptions: { waitUntil: 'load' }, url: 'https://example.com' }
    const result = applyWaitUntil(body, Option.some('networkidle2'))
    expect(result).toStrictEqual({
      gotoOptions: { waitUntil: 'networkidle2' },
      url: 'https://example.com',
    })
  })
})
