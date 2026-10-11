import assert from 'node:assert/strict'
import { spawn } from 'node:child_process'
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'
import { resolve } from 'node:path'
import { test } from 'node:test'

const action = await readFile(new URL('./action.yaml', import.meta.url), 'utf8')
const script = action.split('      run: |\n')[1].replace(/^        /gm, '')

async function runAction(t, { status = 200, filters = '', disconnect = false } = {}) {
  await mkdir('tmp', { recursive: true })
  const directory = await mkdtemp(resolve('tmp/publish-npm-test-'))
  t.after(() => rm(directory, { recursive: true, force: true }))
  const requests = []
  const server = createServer((request, response) => {
    requests.push(request.url)
    if (disconnect) {
      request.socket.destroy()
    } else {
      response.writeHead(status)
      response.end()
    }
  })
  await new Promise((done) => server.listen(0, '127.0.0.1', done))
  t.after(() => new Promise((done) => server.close(done)))
  const registry = `http://127.0.0.1:${server.address().port}/`
  await writeFile(
    resolve(directory, 'package.json'),
    JSON.stringify({
      name: '@example/package',
      version: '0.1.0',
      publishConfig: { registry },
    }),
  )
  await mkdir(resolve(directory, 'bin'))
  await writeFile(resolve(directory, 'bin/nix'), '#!/bin/sh\nexit 0\n', { mode: 0o755 })
  // Record staging instead of publishing anything. Node and curl are real executables.
  await writeFile(resolve(directory, 'bin/vp'), '#!/bin/sh\nprintf "%s\\n" "$@" > "$PUBLISH_CALL"\n', { mode: 0o755 })
  const callPath = resolve(directory, 'publish-call')
  const child = spawn('bash', ['--noprofile', '--norc', '-e', '-o', 'pipefail', '-c', script], {
    cwd: directory,
    env: {
      ...process.env,
      PATH: `${resolve(directory, 'bin')}:${process.env.PATH}`,
      GITHUB_WORKSPACE: directory,
      PUBLISH_FILTERS: filters,
      PUBLISH_CALL: callPath,
    },
  })
  let stdout = ''
  let stderr = ''
  child.stdout.on('data', (data) => {
    stdout += data
  })
  child.stderr.on('data', (data) => {
    stderr += data
  })
  const exitCode = await new Promise((done, reject) => {
    child.once('error', reject)
    child.once('close', done)
  })
  const calls = await readFile(callPath, 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return ''
    throw error
  })
  return { exitCode, stdout, stderr, calls, requests }
}

test('published scoped version skips staging successfully', async (t) => {
  const result = await runAction(t)
  assert.equal(result.exitCode, 0, result.stderr)
  assert.match(result.stdout, /v0\.1\.0 already published\. Skipping\./)
  assert.equal(result.calls, '')
  assert.deepEqual(result.requests, ['/%40example%2Fpackage/0.1.0'])
})

test('missing version stages with provenance', async (t) => {
  const result = await runAction(t, { status: 404 })
  assert.equal(result.exitCode, 0, result.stderr)
  assert.equal(result.calls, 'pm\nstage\npublish\n--provenance\n')
})

test('registry failure fails closed without staging', async (t) => {
  const result = await runAction(t, { status: 503 })
  assert.equal(result.exitCode, 1)
  assert.match(result.stderr, /Registry lookup failed with HTTP 503/)
  assert.equal(result.calls, '')
})

test('network failure fails closed without staging', async (t) => {
  const result = await runAction(t, { disconnect: true })
  assert.notEqual(result.exitCode, 0)
  assert.equal(result.calls, '')
})

test('workspace selectors retain recursive staging without root lookup', async (t) => {
  const result = await runAction(t, { filters: '@example/one\r\n\n@example/two\n' })
  assert.equal(result.exitCode, 0, result.stderr)
  assert.deepEqual(result.requests, [])
  assert.equal(result.calls, 'pm\nstage\npublish\n-r\n--provenance\n--filter\n@example/one\n--filter\n@example/two\n')
})
