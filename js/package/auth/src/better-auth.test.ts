import { describe, expect, it } from 'vite-plus/test'

import { decodeBetterAuthUser, toUser } from './better-auth.ts'

describe('decodeBetterAuthUser', () => {
  it('decodes a Better Auth user payload', () => {
    const user = decodeBetterAuthUser({
      email: 'test@example.com',
      id: 'user-123',
    })

    expect(user).toStrictEqual({ email: 'test@example.com', id: 'user-123' })
  })

  it('rejects an invalid Better Auth user payload', () => {
    const user = decodeBetterAuthUser({ id: 'user-123' })

    expect(user).toBeNull()
  })
})

describe('toUser', () => {
  it('keeps the Better Auth id in the shared auth user', () => {
    const user = toUser({
      email: 'test@example.com',
      id: 'user-123',
    })

    expect(user).toStrictEqual({ email: 'test@example.com', id: 'user-123' })
  })
})
