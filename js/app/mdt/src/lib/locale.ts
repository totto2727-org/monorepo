import { Effect, Predicate, String } from 'effect'

import { InvalidLocaleError } from '#@/lib/invalid-locale-error.ts'

export const normalize = (input: string): Effect.Effect<string, InvalidLocaleError> =>
  Effect.gen(function* () {
    const canonical = yield* Effect.try({
      catch: () => new InvalidLocaleError({ input }),
      try: () => Intl.getCanonicalLocales(input),
    })
    const [first] = canonical
    if (Predicate.isNullish(first) || String.isEmpty(first)) {
      return yield* Effect.fail(new InvalidLocaleError({ input }))
    }
    return first.toLowerCase()
  })
