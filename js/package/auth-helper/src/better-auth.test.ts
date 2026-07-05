import { DateTime } from 'effect'
import { describe, expect, it } from 'vite-plus/test'

import { toIdentityProviderAuthUser } from './better-auth.ts'

describe('toIdentityProviderAuthUser', () => {
  it('maps a Better Auth user with a string createdAt value', () => {
    const user = toIdentityProviderAuthUser({
      createdAt: '2026-07-05T00:00:00.000Z',
      email: 'test@example.com',
      id: 'user-123',
    })

    expect(user?.email).toBe('test@example.com')
    expect(user?.id).toBe('user-123')
    expect(user ? DateTime.toDate(user.createdAt).toISOString() : null).toBe('2026-07-05T00:00:00.000Z')
  })

  it('maps a Better Auth user with a Date createdAt value', () => {
    const user = toIdentityProviderAuthUser({
      createdAt: DateTime.toDate(DateTime.makeUnsafe('2026-07-05T00:00:00.000Z')),
      email: 'test@example.com',
      id: 'user-123',
    })

    expect(user ? DateTime.toDate(user.createdAt).toISOString() : null).toBe('2026-07-05T00:00:00.000Z')
  })

  it('rejects a Better Auth user without a usable createdAt value', () => {
    const user = toIdentityProviderAuthUser({
      createdAt: 0,
      email: 'test@example.com',
      id: 'user-123',
    })

    expect(user).toBeNull()
  })
})
