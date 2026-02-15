import { BetterAuthService } from '#@/auth/service.ts'
import { DatabaseService, makeTestDatabaseService } from '#@/db/service.ts'
import { app } from '#api/api.ts'
import { Effect } from '@package/function/effect'

// oxlint-disable-next-line jest/require-hook no-await-expression-member
;(
  await app.pipe(
    Effect.provide(BetterAuthService.Default),
    Effect.provideService(DatabaseService, makeTestDatabaseService()),
    Effect.runPromise,
  )
).listen({
  development: {
    chromeDevToolsAutomaticWorkspaceFolders: true,
    console: true,
    hmr: true,
  },
  port: 3000,
})
