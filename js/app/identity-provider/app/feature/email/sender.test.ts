import { Effect } from 'effect'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vite-plus/test'

import * as Cloudflare from './cloudflare.ts'
import * as Mock from './mock.ts'
import * as Sender from './sender.ts'

describe('EmailSender', () => {
  beforeEach(() => Effect.runPromise(Mock.clearSent()))

  test('mock layer records every sent email', async () => {
    const program = Effect.gen(function* () {
      const sender = yield* Sender.Service
      yield* sender.send({ subject: 'subj-1', text: 'body-1', to: 'a@example.com' })
      yield* sender.send({ subject: 'subj-2', text: 'body-2', to: 'b@example.com' })
      return yield* Mock.getAllSent()
    })

    const sent = await Effect.runPromise(Effect.provide(program, Mock.layer))

    expect(sent).toHaveLength(2)
    expect(sent[0]?.to).toBe('a@example.com')
    expect(sent[1]?.subject).toBe('subj-2')
  })

  describe('cloudflare layer', () => {
    const fetchMock = vi.fn<typeof fetch>()

    beforeEach(() => {
      vi.stubGlobal('fetch', fetchMock)
    })

    afterEach(() => {
      vi.unstubAllGlobals()
      fetchMock.mockReset()
    })

    test('returns EmailSendError when API responds with 401', async () => {
      fetchMock.mockResolvedValueOnce(new Response('Unauthorized', { status: 401 }))

      const layer = Cloudflare.makeLayer({
        accountId: 'test-account',
        apiToken: 'invalid-token',
        fromAddress: 'auth@dev.example.com',
      })

      const program = Effect.gen(function* () {
        const sender = yield* Sender.Service
        return yield* sender.send({ subject: 's', text: 't', to: 'x@example.com' })
      })

      const result = await Effect.runPromise(Effect.result(Effect.provide(program, layer)))

      expect(result._tag).toBe('Failure')
      if (result._tag === 'Failure') {
        expect(result.failure._tag).toBe('EmailSendError')
        expect(result.failure.message).toContain('401')
      }
    })
  })
})
