import { AuthMiddleware } from '#@/auth/middleware.ts'
import { makeSPAWildcardRequestHandler } from '#@/bun/spa.ts'
import indexHTML from '#public/index.html'
import { logger } from '@bogeychan/elysia-logger'
import { Effect } from '@totto2727/fp/effect'
import { Elysia } from 'elysia'

const isDev = import.meta.env.NODE_ENV === 'development'
const sqaOption = { isDev }

export const app = Effect.gen(function* () {
  const runtime = yield* Effect.runtime()
  const authMiddle = yield* AuthMiddleware

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
    .use(authMiddle)
    .get('/api', () => 'Hello Elysia!')
    .get('/api/user', ({ user }) => user, {
      requireAuthentication: true,
    })
})
