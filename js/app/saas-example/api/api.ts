import { makeSPAWildcardRequestHandler } from '#@/bun/spa.ts'
import indexHTML from '#public/index.html'
import { logger } from '@bogeychan/elysia-logger'
import { Effect } from '@package/function/effect'
import { Elysia } from 'elysia'

const isDev = import.meta.env.NODE_ENV === 'development'
const sqaOption = { isDev }

export const app = Effect.gen(function* () {
  const runtime = yield* Effect.runtime()
  return new Elysia({
    serve: {
      routes: {
        '/app': indexHTML,
        '/app/*': makeSPAWildcardRequestHandler(indexHTML, sqaOption),
      },
    },
  })
    .use(logger())
    .resolve(() => ({ runtime }))
    .get('/', () => 'Hello Elysia!')
})
