import { app } from '#api/api.ts'
import { Effect } from '@package/function/effect'

// oxlint-disable-next-line jest/require-hook no-await-expression-member
;(await Effect.runPromise(app)).listen({
  development: {
    chromeDevToolsAutomaticWorkspaceFolders: true,
    console: true,
    hmr: true,
  },
  port: 3000,
})
