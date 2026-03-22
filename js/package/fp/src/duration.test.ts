import { DateTime, Effect } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import { DurationFormatterCache, format } from './duration.ts'

describe('format', () => {
  test('EN', () => {
    Effect.gen(function* () {
      const result = yield* format(
        DateTime.makeUnsafe('2023-01-01T00:00:00+00:00'),
        DateTime.makeUnsafe('2023-01-01T01:00:00+00:00'),
        {
          locale: 'en',
        },
      )
      expect(result).toBe('1 hr')
    }).pipe(Effect.provide(DurationFormatterCache.layer), Effect.runSync)
  })

  test('JA', () => {
    Effect.gen(function* () {
      const result = yield* format(
        DateTime.makeUnsafe('2023-01-01T00:00:00+00:00'),
        DateTime.makeUnsafe('2023-01-01T01:00:00+00:00'),
        {
          locale: 'ja',
        },
      )
      expect(result).toBe('1 時間')
    }).pipe(Effect.provide(DurationFormatterCache.layer), Effect.runSync)
  })
})
