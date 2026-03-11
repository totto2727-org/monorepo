import { DurationFormat } from '@formatjs/intl-durationformat'
import { Array, DateTime, Duration, Effect, HashMap, Layer, Option, Ref, ServiceMap } from 'effect'

type DurationFormatterCacheRef = Ref.Ref<HashMap.HashMap<readonly string[], DurationFormat>>

/**
 * @internal
 */
export const DurationFormatterCacheBase: ServiceMap.ServiceClass<
  DurationFormatterCache,
  '@totto2727/fp/duration/DurationFormatterCache',
  DurationFormatterCacheRef
> & {
  readonly make: Effect.Effect<DurationFormatterCacheRef, never, never>
} = ServiceMap.Service<DurationFormatterCache>()('@totto2727/fp/duration/DurationFormatterCache', {
  make: Ref.make(HashMap.empty()),
})

/** Effect service that provides CUID generation. */
export class DurationFormatterCache extends DurationFormatterCacheBase {
  static readonly layer: Layer.Layer<DurationFormatterCache, never, never> = Layer.effect(this, this.make)
}

const shortFormatterFactory = Effect.fn(function* (option: { locale: string | string[] }) {
  const durationFormatterCacheRef = yield* DurationFormatterCache
  const durationFormatterCache = yield* Ref.get(durationFormatterCacheRef)

  const keys = Array.ensure(option.locale)
  const cached = HashMap.get(durationFormatterCache, keys)
  if (Option.isSome(cached)) {
    return cached.value
  }

  const formatter = new DurationFormat(option.locale, {
    style: 'narrow',
  })
  Ref.set(durationFormatterCacheRef, HashMap.set(durationFormatterCache, keys, formatter))
  return formatter
})

/**
 * Function that calculates the time difference between two dates and returns it as a string
 *
 * Note that only some properties of the time difference are displayed, not all.
 *
 * DurationFormat instances used internally are cached with locale values as keys.
 */
export const formatShort: (
  from: DateTime.DateTime,
  to: DateTime.DateTime,
  option: {
    locale: string | string[]
  },
) => Effect.Effect<string, never, DurationFormatterCache> = Effect.fn(function* (from, to, option) {
  const formatter = yield* shortFormatterFactory(option)

  const duration = DateTime.distance(from, to)

  const parts = Duration.parts(duration)

  if (parts.days >= 365 / 12) {
    return formatter.format({
      months: Math.trunc(parts.days / (365 / 12)) % 12,
      years: Math.trunc(parts.days / 365),
    })
  } else if (parts.days >= 7) {
    return formatter.format({
      weeks: Math.trunc(parts.days / 7),
    })
  } else if (parts.days !== 0) {
    return formatter.format({
      days: parts.days,
    })
  } else if (parts.hours !== 0) {
    return formatter.format({
      hours: parts.hours,
      minutes: parts.minutes,
    })
  }

  return formatter.format(Duration.parts(duration))
})
