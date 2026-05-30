import * as Fs from 'node:fs/promises'
import * as Os from 'node:os'
import * as NodePath from 'node:path'

import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'

import { hasSupportedPluginFormat } from './plugin-format.ts'

let tmpDir = ''

beforeEach(async () => {
  tmpDir = await Fs.mkdtemp(NodePath.join(Os.tmpdir(), 'c-plugin-test-'))
})

afterEach(async () => {
  if (tmpDir) {
    await Fs.rm(tmpDir, { force: true, recursive: true })
  }
})

describe('hasSupportedPluginFormat', () => {
  test('returns true for each supported plugin format directory', async () => {
    for (const kind of allKinds) {
      const dir = NodePath.join(tmpDir, `${kind}-root`)
      await Fs.mkdir(dir, { recursive: true })
      await Fs.mkdir(NodePath.join(dir, getKindConfig(kind).configDir), { recursive: true })

      await expect(
        Effect.runPromise(hasSupportedPluginFormat(dir).pipe(Effect.provide(NodeServices.layer))),
      ).resolves.toBe(true)
    }
  })

  test('returns false for empty directory', async () => {
    await expect(
      Effect.runPromise(hasSupportedPluginFormat(tmpDir).pipe(Effect.provide(NodeServices.layer))),
    ).resolves.toBe(false)
  })

  test('returns false for nonexistent directory', async () => {
    await expect(
      Effect.runPromise(
        hasSupportedPluginFormat(NodePath.join(tmpDir, 'missing')).pipe(Effect.provide(NodeServices.layer)),
      ),
    ).resolves.toBe(false)
  })
})
