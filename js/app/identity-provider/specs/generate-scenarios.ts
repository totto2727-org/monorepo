/* oxlint-disable eslint/complexity, eslint/func-style, promise/avoid-new, promise/prefer-await-to-callbacks, rules/force-array-empty, rules/force-predicate, rules/no-error-property-access, rules/no-instanceof-error, rules/no-let, rules/no-node-imports, rules/no-type-predicate, unicorn/no-array-sort, unicorn/no-useless-undefined, unicorn/relative-url-style, unicorn/text-encoding-identifier-case -- This standalone generator needs direct argv process control and fsync-backed atomic publication while parsing FSL's untyped JSON contract. */
import { spawn } from 'node:child_process'
import { mkdir, open, rename, rm } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import type { Readable } from 'node:stream'
import { fileURLToPath } from 'node:url'

const actionNames = [
  'request_protected_without_session',
  'request_protected_with_session',
  'open_login_preserve',
  'open_login_oauth',
  'open_login_unrelated',
  'callback_without_session',
  'callback_with_session',
  'callback_after_consumption',
] as const

const specificationPath = fileURLToPath(new URL('./return-to-session.fsl', import.meta.url))
const outputPath = fileURLToPath(new URL('./generated/return-to-session.scenarios.json', import.meta.url))
const generationTimeoutMs = 30_000

class ScenarioValidationError extends Error {
  public constructor(message: string) {
    super(message)
    this.name = 'ScenarioValidationError'
  }
}

function fail(message: string): never {
  throw new ScenarioValidationError(message)
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

const requireExactKeys = (value: Record<string, unknown>, keys: readonly string[], location: string): void => {
  const actualKeys = Object.keys(value).sort()
  const expectedKeys = [...keys].sort()
  if (actualKeys.length !== expectedKeys.length || actualKeys.some((key, index) => key !== expectedKeys[index])) {
    fail(`${location} has unexpected keys`)
  }
}

const requireString = (value: unknown, location: string): string => {
  if (typeof value !== 'string') {
    fail(`${location} must be a string`)
  }
  return value
}

const requireAction = (value: unknown, location: string): void => {
  if (!actionNames.some((action) => action === value)) {
    fail(`${location} must be a canonical action`)
  }
}

const requireState = (value: unknown, location: string): void => {
  if (!isObject(value)) {
    fail(`${location} must be an object`)
  }
  requireExactKeys(value, ['outcome', 'request_category', 'session', 'stored_target'], location)
  for (const key of Object.keys(value)) {
    requireString(value[key], `${location}.${key}`)
  }
}

const validateScenarios = (value: unknown): void => {
  if (!isObject(value)) {
    fail('fslc output must be a JSON object')
  }
  requireExactKeys(value, ['convention', 'depth', 'fsl', 'result', 'scenarios', 'spec', 'warnings'], 'fslc output')
  if (value.fsl !== '1.0' || value.result !== 'scenarios' || value.spec !== 'ReturnToSession' || value.depth !== 8) {
    fail('fslc output does not describe the expected ReturnToSession scenarios')
  }
  requireString(value.convention, 'fslc output.convention')
  if (!Array.isArray(value.warnings) || value.warnings.length > 0) {
    fail('fslc output.warnings must be empty')
  }
  if (!Array.isArray(value.scenarios) || value.scenarios.length !== actionNames.length) {
    fail('fslc output.scenarios must contain the canonical action coverage')
  }

  const coveredActions = new Set<string>()
  for (const [scenarioIndex, scenario] of value.scenarios.entries()) {
    const location = `fslc output.scenarios[${scenarioIndex}]`
    if (!isObject(scenario)) {
      fail(`${location} must be an object`)
    }
    requireExactKeys(scenario, ['action', 'expected_states', 'initial_state', 'kind', 'name', 'steps'], location)
    requireString(scenario.name, `${location}.name`)
    if (scenario.kind !== 'action_coverage') {
      fail(`${location}.kind must be action_coverage`)
    }
    requireAction(scenario.action, `${location}.action`)
    if (typeof scenario.action !== 'string' || coveredActions.has(scenario.action)) {
      fail(`${location}.action must be covered exactly once`)
    }
    coveredActions.add(scenario.action)
    requireState(scenario.initial_state, `${location}.initial_state`)
    if (!Array.isArray(scenario.steps) || scenario.steps.length === 0) {
      fail(`${location}.steps must be nonempty`)
    }
    for (const [stepIndex, step] of scenario.steps.entries()) {
      const stepLocation = `${location}.steps[${stepIndex}]`
      if (!isObject(step)) {
        fail(`${stepLocation} must be an object`)
      }
      requireExactKeys(step, ['action', 'params'], stepLocation)
      requireAction(step.action, `${stepLocation}.action`)
      if (!isObject(step.params) || Object.keys(step.params).length > 0) {
        fail(`${stepLocation}.params must be an empty object`)
      }
    }
    if (!Array.isArray(scenario.expected_states) || scenario.expected_states.length !== scenario.steps.length) {
      fail(`${location}.expected_states must have one post-step state per step`)
    }
    for (const [stateIndex, state] of scenario.expected_states.entries()) {
      requireState(state, `${location}.expected_states[${stateIndex}]`)
    }
  }
  if (coveredActions.size !== actionNames.length || actionNames.some((action) => !coveredActions.has(action))) {
    fail('fslc output does not cover every canonical action')
  }
}

const readOutput = async (stream: Readable | null): Promise<string> => {
  if (stream === null) {
    return ''
  }
  let output = ''
  for await (const chunk of stream) {
    output += Buffer.isBuffer(chunk) ? chunk.toString('utf8') : String(chunk)
  }
  return output
}

const runFslc = async (): Promise<string> => {
  const child = spawn('fslc', ['scenarios', specificationPath, '--depth', '8'], {
    cwd: dirname(specificationPath),
    detached: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  })
  const stdout = readOutput(child.stdout)
  const stderr = readOutput(child.stderr)
  let timedOut = false
  const timeout = setTimeout(() => {
    timedOut = true
    if (child.pid !== undefined) {
      process.kill(-child.pid, 'SIGKILL')
    }
  }, generationTimeoutMs)
  let exitCode: number | null
  try {
    exitCode = await new Promise<number | null>((resolve, reject) => {
      child.once('close', resolve)
      child.once('error', reject)
    })
  } catch (error) {
    await Promise.allSettled([stdout, stderr])
    throw error
  } finally {
    clearTimeout(timeout)
  }
  const [output, diagnostics] = await Promise.all([stdout, stderr])
  if (timedOut) {
    fail(`fslc did not finish within ${generationTimeoutMs}ms`)
  }
  if (exitCode !== 0) {
    fail(`fslc scenarios failed with exit ${exitCode}: ${diagnostics.trim()}`)
  }
  return output
}

const publish = async (content: string): Promise<void> => {
  const outputDirectory = dirname(outputPath)
  await mkdir(outputDirectory, { recursive: true })
  const temporaryPath = join(outputDirectory, `.return-to-session.scenarios.${process.pid}.${crypto.randomUUID()}.tmp`)
  try {
    const file = await open(temporaryPath, 'w', 0o600)
    try {
      await file.writeFile(content)
      await file.sync()
    } finally {
      await file.close()
    }
    await rename(temporaryPath, outputPath)
  } catch (error) {
    await rm(temporaryPath, { force: true })
    throw error
  }
}

const main = async (): Promise<void> => {
  const output = await runFslc()
  let parsed: unknown
  try {
    parsed = JSON.parse(output)
  } catch (error) {
    if (error instanceof SyntaxError) {
      fail(`fslc output is not strict JSON: ${error.message}`)
    }
    throw error
  }
  validateScenarios(parsed)
  await publish(output)
}

void main().then(
  () => undefined,
  (error: unknown) => {
    console.error(error instanceof Error ? error.message : 'scenario generation failed')
    process.exitCode = 1
  },
)
