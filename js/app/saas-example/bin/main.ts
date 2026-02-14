import { app } from '#api/api.ts'
import { Effect } from '@package/function/effect'
//
// oxlint-disable-next-line jest/require-hook no-await-expression-member
;(await Effect.runPromise(app)).listen({
  port: 3000,
})
