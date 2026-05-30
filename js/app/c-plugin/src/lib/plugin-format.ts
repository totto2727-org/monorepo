import { Effect, FileSystem } from 'effect'

import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'

export const hasSupportedPluginFormat = (dirPath: string): Effect.Effect<boolean, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    for (const kind of allKinds) {
      const exists = yield* fs
        .exists(`${dirPath}/${getKindConfig(kind).configDir}`)
        .pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        return true
      }
    }
    return false
  })
