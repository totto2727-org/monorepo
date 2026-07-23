import { describe, expect, test } from 'vite-plus/test'

import { initialUserName } from './user-name.ts'

describe('initialUserName', () => {
  test('uses the email local part when the supplied name is blank', () => {
    const user = { email: 'alice@example.com', name: '' }

    const name = initialUserName(user)

    expect(name).toBe('alice')
  })

  test('keeps a supplied non-blank name', () => {
    const user = { email: 'alice@example.com', name: 'Alice Example' }

    const name = initialUserName(user)

    expect(name).toBe('Alice Example')
  })
})
