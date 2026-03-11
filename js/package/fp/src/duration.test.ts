import { describe, expect, test } from 'bun:test'
import { DateTime, Effect } from 'effect'

import { DurationFormatterCache, formatShort } from './duration.ts'

describe('formatShort', () => {
  test('EN', () => {
    Effect.gen(function* () {
      const result = yield* formatShort(
        DateTime.makeUnsafe('2023-01-01T00:00:00+00:00'),
        DateTime.makeUnsafe('2023-01-01T01:00:00+00:00'),
        {
          locale: 'en',
        },
      )
      expect(result).toBe('1h')
    }).pipe(Effect.provide(DurationFormatterCache.layer), Effect.runSync)
  })

  test('JA', () => {
    Effect.gen(function* () {
      const result = yield* formatShort(
        DateTime.makeUnsafe('2023-01-01T00:00:00+00:00'),
        DateTime.makeUnsafe('2023-01-01T01:00:00+00:00'),
        {
          locale: 'ja',
        },
      )
      expect(result).toBe('1時間')
    }).pipe(Effect.provide(DurationFormatterCache.layer), Effect.runSync)
  })
})
