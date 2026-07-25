// oxlint-disable-next-line rules/no-node-imports -- The test boundary must read the regenerated ignored artifact without Vite transform caching.
import { readFile } from 'node:fs/promises'

import { Effect, Predicate, Schema } from 'effect'
import { afterAll, describe, expect, it, vi } from 'vite-plus/test'

import type * as AuthMiddlewareModule from './middleware.ts'

// allow: SIZE_OK — the strict generated-data schema and canonical HTTP action table must remain at this test boundary.
vi.mock('#@/feature/runtime/hono.ts', async () => {
  const { factory } = await import('#@/feature/share/lib/hono/factory.ts')
  return {
    middleware: factory.createMiddleware(async (_ctx, next) => {
      await next()
    }),
  }
})

vi.mock('#@/feature/auth/middleware.ts', async (importOriginal) => {
  const actual = await importOriginal<typeof AuthMiddlewareModule>()
  const { factory } = await import('#@/feature/share/lib/hono/factory.ts')
  return {
    ...actual,
    authMiddleware: factory.createMiddleware(async (ctx, next) => {
      if (ctx.req.header('x-test-authenticated') === 'true') {
        ctx.set('user', {
          email: 'test@example.com',
          id: 'user-123',
        })
      }
      await next()
    }),
  }
})

const canonicalActions = [
  'request_protected_without_session',
  'request_protected_with_session',
  'open_login_preserve',
  'open_login_oauth',
  'open_login_unrelated',
  'callback_without_session',
  'callback_with_session',
  'callback_after_consumption',
] as const

const Session = Schema.Literals(['Absent', 'Present'])
const StoredTarget = Schema.Literals(['NoTarget', 'InternalTarget', 'OAuthAuthorizeTarget'])
const RequestCategory = Schema.Literals([
  'NoRequest',
  'ProtectedWithoutSession',
  'ProtectedWithSession',
  'OpenLoginPreserve',
  'OpenLoginOAuth',
  'OpenLoginUnrelated',
  'CallbackWithoutSession',
  'CallbackWithSession',
  'CallbackAfterConsumption',
])
const Outcome = Schema.Literals([
  'Idle',
  'LoginRedirect',
  'ProtectedPassThrough',
  'LoginRendered',
  'SessionRequired',
  'InternalRedirect',
  'AccountFallback',
  'ExternalRedirect',
])
const Action = Schema.Literals(canonicalActions)
const ModelState = Schema.Struct({
  outcome: Outcome,
  request_category: RequestCategory,
  session: Session,
  stored_target: StoredTarget,
})
const Step = Schema.Struct({
  action: Action,
  params: Schema.Record(Schema.String, Schema.Never),
})
const Scenario = Schema.Struct({
  action: Action,
  expected_states: Schema.NonEmptyArray(ModelState),
  initial_state: ModelState,
  kind: Schema.Literal('action_coverage'),
  name: Schema.NonEmptyString,
  steps: Schema.NonEmptyArray(Step),
})
const ScenarioEnvelope = Schema.Struct({
  convention: Schema.NonEmptyString,
  depth: Schema.Literal(8),
  fsl: Schema.Literal('1.0'),
  result: Schema.Literal('scenarios'),
  scenarios: Schema.NonEmptyArray(Scenario),
  spec: Schema.Literal('ReturnToSession'),
  warnings: Schema.Tuple([]),
})
const decodeScenarioEnvelope = Schema.decodeUnknownEffect(Schema.fromJsonString(ScenarioEnvelope))

type Action = typeof Action.Type
type ModelState = typeof ModelState.Type
type ScenarioEnvelope = typeof ScenarioEnvelope.Type
type Session = typeof Session.Type
type StoredTarget = typeof StoredTarget.Type

class ScenarioContractError extends Error {
  public override readonly name = 'ScenarioContractError'
  public readonly violation: string

  public constructor(violation: string) {
    super(violation)
    this.violation = violation
  }
}

const parseScenarioEnvelope = async (input: string): Promise<ScenarioEnvelope> => {
  const envelope = await Effect.runPromise(decodeScenarioEnvelope(input, { onExcessProperty: 'error' }))
  if (envelope.scenarios.length !== canonicalActions.length) {
    throw new ScenarioContractError('scenarios must cover the eight canonical actions exactly once')
  }
  const coveredActions = new Set<Action>()
  const executedActionNames = new Set<Action>()
  for (const scenario of envelope.scenarios) {
    if (coveredActions.has(scenario.action)) {
      throw new ScenarioContractError(`duplicate action coverage: ${scenario.action}`)
    }
    coveredActions.add(scenario.action)
    if (!scenario.steps.some((step) => step.action === scenario.action)) {
      throw new ScenarioContractError(`scenario ${scenario.name} does not execute its covered action`)
    }
    if (scenario.steps.length !== scenario.expected_states.length) {
      throw new ScenarioContractError(`scenario ${scenario.name} must have one expected state per step`)
    }
    for (const step of scenario.steps) {
      executedActionNames.add(step.action)
    }
  }
  if (
    canonicalActions.some((action) => !coveredActions.has(action)) ||
    canonicalActions.some((action) => !executedActionNames.has(action))
  ) {
    throw new ScenarioContractError('scenarios must emit and execute every canonical action')
  }
  return envelope
}

const scenariosJson = await readFile(
  new URL('../../../specs/generated/return-to-session.scenarios.json', import.meta.url),
  'utf-8',
)
const envelope = await parseScenarioEnvelope(scenariosJson)
const { default: app } = await import('../../app.tsx')
const { loginReturnToCookieName } = await import('./cookie.ts')
const { preserveReturnToLoginPath } = await import('./query-parameter.ts')

const targetValues = {
  InternalTarget: '/app/account?tab=security',
  NoTarget: undefined,
  OAuthAuthorizeTarget:
    '/api/v1/auth/oauth2/authorize?client_id=client-123&redirect_uri=https%3A%2F%2Fclient.example%2Fcallback&scope=openid',
} as const satisfies Record<StoredTarget, string | undefined>

interface HarnessState {
  readonly cookie: string | undefined
  readonly session: Session
}

interface ActionDefinition {
  readonly expectedLocation: '/app/account' | '/login' | 'preserve' | 'stored' | null
  readonly outcome: ModelState['outcome']
  readonly path: string
  readonly requestCategory: ModelState['request_category']
  readonly session: Session | 'Keep'
  readonly status: 200 | 302
}

const actionDefinitions = {
  callback_after_consumption: {
    expectedLocation: '/app/account',
    outcome: 'AccountFallback',
    path: '/login/callback',
    requestCategory: 'CallbackAfterConsumption',
    session: 'Present',
    status: 302,
  },
  callback_with_session: {
    expectedLocation: 'stored',
    outcome: 'InternalRedirect',
    path: '/login/callback',
    requestCategory: 'CallbackWithSession',
    session: 'Present',
    status: 302,
  },
  callback_without_session: {
    expectedLocation: '/login',
    outcome: 'SessionRequired',
    path: '/login/callback',
    requestCategory: 'CallbackWithoutSession',
    session: 'Absent',
    status: 302,
  },
  open_login_oauth: {
    expectedLocation: null,
    outcome: 'LoginRendered',
    path: '/login?client_id=client-123&redirect_uri=https%3A%2F%2Fclient.example%2Fcallback&scope=openid',
    requestCategory: 'OpenLoginOAuth',
    session: 'Keep',
    status: 200,
  },
  open_login_preserve: {
    expectedLocation: null,
    outcome: 'LoginRendered',
    path: preserveReturnToLoginPath,
    requestCategory: 'OpenLoginPreserve',
    session: 'Keep',
    status: 200,
  },
  open_login_unrelated: {
    expectedLocation: null,
    outcome: 'LoginRendered',
    path: '/login',
    requestCategory: 'OpenLoginUnrelated',
    session: 'Keep',
    status: 200,
  },
  request_protected_with_session: {
    expectedLocation: null,
    outcome: 'ProtectedPassThrough',
    path: '/app/account',
    requestCategory: 'ProtectedWithSession',
    session: 'Present',
    status: 200,
  },
  request_protected_without_session: {
    expectedLocation: 'preserve',
    outcome: 'LoginRedirect',
    path: '/app/account?tab=security',
    requestCategory: 'ProtectedWithoutSession',
    session: 'Absent',
    status: 302,
  },
} as const satisfies Record<Action, ActionDefinition>

const assertNever = (value: never): never => {
  throw new ScenarioContractError(`unhandled runner variant: ${String(value)}`)
}

const cookieForTarget = (target: StoredTarget): string | undefined => {
  const value = targetValues[target]
  return Predicate.isUndefined(value) ? undefined : `${loginReturnToCookieName}=${encodeURIComponent(value)}`
}

const storedTargetFromCookie = (cookie: string | undefined): StoredTarget => {
  if (Predicate.isUndefined(cookie)) {
    return 'NoTarget'
  }
  const value = decodeURIComponent(cookie.slice(loginReturnToCookieName.length + 1))
  if (value === targetValues.InternalTarget) {
    return 'InternalTarget'
  }
  if (value === targetValues.OAuthAuthorizeTarget) {
    return 'OAuthAuthorizeTarget'
  }
  throw new ScenarioContractError(`runner observed an unknown stored target: ${value}`)
}

const requestHeaders = (state: HarnessState): Readonly<Record<string, string>> => ({
  ...(Predicate.isUndefined(state.cookie) ? {} : { cookie: state.cookie }),
  ...(state.session === 'Present' ? { 'x-test-authenticated': 'true' } : {}),
})

const nextCookie = (current: string | undefined, response: Response): string | undefined => {
  const setCookie = response.headers.get('set-cookie')
  if (Predicate.isNull(setCookie)) {
    return current
  }
  const [cookiePair = ''] = setCookie.split(';', 1)
  return cookiePair === `${loginReturnToCookieName}=` ? undefined : cookiePair
}

const resolveSession = (transition: ActionDefinition['session'], current: Session): Session => {
  switch (transition) {
    case 'Absent':
    case 'Present': {
      return transition
    }
    case 'Keep': {
      return current
    }
    default: {
      return assertNever(transition)
    }
  }
}

const resolveExpectedLocation = (
  expected: ActionDefinition['expectedLocation'],
  storedTarget: StoredTarget,
): string | null => {
  switch (expected) {
    case '/app/account':
    case '/login': {
      return expected
    }
    case 'preserve': {
      return preserveReturnToLoginPath
    }
    case 'stored': {
      const target = targetValues[storedTarget]
      if (Predicate.isUndefined(target)) {
        throw new ScenarioContractError('callback_with_session requires a stored target')
      }
      return target
    }
    case null: {
      return null
    }
    default: {
      return assertNever(expected)
    }
  }
}

const executeAction = async (
  action: Action,
  current: HarnessState,
): Promise<{ readonly harness: HarnessState; readonly observed: ModelState }> => {
  const definition = actionDefinitions[action]
  const requestState = { ...current, session: resolveSession(definition.session, current.session) }
  const storedTarget = storedTargetFromCookie(requestState.cookie)
  const response = await app.request(definition.path, { headers: requestHeaders(requestState) })
  expect(response.status).toBe(definition.status)
  expect(response.headers.get('location')).toBe(resolveExpectedLocation(definition.expectedLocation, storedTarget))
  const harness = { ...requestState, cookie: nextCookie(requestState.cookie, response) }
  return {
    harness,
    observed: {
      outcome: definition.outcome,
      request_category: definition.requestCategory,
      session: harness.session,
      stored_target: storedTargetFromCookie(harness.cookie),
    },
  }
}

const summary = {
  actionExecutions: 0,
  emitted: envelope.scenarios.length,
  executed: 0,
  skipped: 0,
}

afterAll(() => {
  expect(summary.emitted).toBeGreaterThan(0)
  expect(summary.executed).toBe(summary.emitted)
  expect(summary.skipped).toBe(0)
  console.info(
    `FSL runner summary: emitted=${summary.emitted} executed=${summary.executed} skipped=${summary.skipped} actions=${summary.actionExecutions} warnings=${envelope.warnings.length}`,
  )
})

describe('generated ReturnToSession scenarios', () => {
  it('executes every emitted scenario and matches every post-step state', async () => {
    for (const scenario of envelope.scenarios) {
      let harness: HarnessState = {
        cookie: cookieForTarget(scenario.initial_state.stored_target),
        session: scenario.initial_state.session,
      }
      for (const [stepIndex, step] of scenario.steps.entries()) {
        const { harness: nextHarness, observed } = await executeAction(step.action, harness)
        expect(observed, `${scenario.name} step ${stepIndex}`).toStrictEqual(scenario.expected_states[stepIndex])
        harness = nextHarness
        summary.actionExecutions += 1
      }
      summary.executed += 1
    }
  })
})
