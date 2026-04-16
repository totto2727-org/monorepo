import { Effect, Exit, Option, Predicate } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { resolve } from './auth.ts'

const setEnv = (key: string, value: string | undefined): string | undefined => {
  const original = process.env[key]
  if (Predicate.isUndefined(value)) {
    Reflect.deleteProperty(process.env, key)
  } else {
    process.env[key] = value
  }
  return original
}

const restoreEnv = (key: string, original: string | undefined): void => {
  if (Predicate.isUndefined(original)) {
    Reflect.deleteProperty(process.env, key)
  } else {
    process.env[key] = original
  }
}

describe('resolve', () => {
  test('uses flag values when provided', async () => {
    const result = await Effect.runPromise(
      resolve({ accountId: Option.some('acct-123'), apiToken: Option.some('token-abc') }),
    )
    expect(result).toStrictEqual({ accountId: 'acct-123', apiToken: 'token-abc' })
  })

  test('uses env vars when flags are not provided', async () => {
    const origAcct = setEnv('CLOUDFLARE_ACCOUNT_ID', 'env-acct')
    const origToken = setEnv('CLOUDFLARE_API_TOKEN', 'env-token')
    try {
      const result = await Effect.runPromise(resolve({ accountId: Option.none(), apiToken: Option.none() }))
      expect(result).toStrictEqual({ accountId: 'env-acct', apiToken: 'env-token' })
    } finally {
      restoreEnv('CLOUDFLARE_ACCOUNT_ID', origAcct)
      restoreEnv('CLOUDFLARE_API_TOKEN', origToken)
    }
  })

  test('flag values take priority over env vars', async () => {
    const origAcct = setEnv('CLOUDFLARE_ACCOUNT_ID', 'env-acct')
    const origToken = setEnv('CLOUDFLARE_API_TOKEN', 'env-token')
    try {
      const result = await Effect.runPromise(
        resolve({ accountId: Option.some('flag-acct'), apiToken: Option.some('flag-token') }),
      )
      expect(result).toStrictEqual({ accountId: 'flag-acct', apiToken: 'flag-token' })
    } finally {
      restoreEnv('CLOUDFLARE_ACCOUNT_ID', origAcct)
      restoreEnv('CLOUDFLARE_API_TOKEN', origToken)
    }
  })

  test('fails with AuthError when accountId is missing', async () => {
    const origAcct = setEnv('CLOUDFLARE_ACCOUNT_ID', undefined)
    const origToken = setEnv('CLOUDFLARE_API_TOKEN', 'token')
    try {
      const exit = await Effect.runPromiseExit(resolve({ accountId: Option.none(), apiToken: Option.none() }))
      expect(Exit.isFailure(exit)).toBe(true)
    } finally {
      restoreEnv('CLOUDFLARE_ACCOUNT_ID', origAcct)
      restoreEnv('CLOUDFLARE_API_TOKEN', origToken)
    }
  })

  test('fails with AuthError when apiToken is missing', async () => {
    const origAcct = setEnv('CLOUDFLARE_ACCOUNT_ID', 'acct')
    const origToken = setEnv('CLOUDFLARE_API_TOKEN', undefined)
    try {
      const exit = await Effect.runPromiseExit(resolve({ accountId: Option.none(), apiToken: Option.none() }))
      expect(Exit.isFailure(exit)).toBe(true)
    } finally {
      restoreEnv('CLOUDFLARE_ACCOUNT_ID', origAcct)
      restoreEnv('CLOUDFLARE_API_TOKEN', origToken)
    }
  })

  test('ignores empty string env vars', async () => {
    const origAcct = setEnv('CLOUDFLARE_ACCOUNT_ID', '')
    const origToken = setEnv('CLOUDFLARE_API_TOKEN', '')
    try {
      const exit = await Effect.runPromiseExit(resolve({ accountId: Option.none(), apiToken: Option.none() }))
      expect(Exit.isFailure(exit)).toBe(true)
    } finally {
      restoreEnv('CLOUDFLARE_ACCOUNT_ID', origAcct)
      restoreEnv('CLOUDFLARE_API_TOKEN', origToken)
    }
  })
})
