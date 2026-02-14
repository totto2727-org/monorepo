import indexHTML from '#public/index.html'
import { logger } from '@bogeychan/elysia-logger'
import { Effect } from '@package/function/effect'
import { Elysia } from 'elysia'

export const app = Effect.gen(function* () {
  const runtime = yield* Effect.runtime()
  return new Elysia({
    serve: {
      routes: {
        '/app': indexHTML,
        '/app/*': indexHTML,
      },
    },
  })
    .use(logger())
    .resolve(() => ({ runtime }))
    .get('/', () => 'Hello Elysia!')
})
