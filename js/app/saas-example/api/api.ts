import { logger } from '@bogeychan/elysia-logger'
import { staticPlugin } from '@elysiajs/static'
import { Effect } from '@package/function/effect'
import { Elysia } from 'elysia'

export const app = Effect.gen(function* () {
  const runtime = yield* Effect.runtime()

  return new Elysia()
    .use(logger())
    .use(
      yield* Effect.promise(() =>
        staticPlugin({
          prefix: '/app',
        }),
      ),
    )
    .resolve(() => ({ runtime }))
    .get('/', () => 'Hello Elysia!')
})
