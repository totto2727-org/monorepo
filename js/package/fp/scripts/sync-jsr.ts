import { NodeServices } from '@effect/platform-node'
import { Effect, FileSystem } from 'effect'

import jsrOriginal from '../jsr.json' with { type: 'json' }
import pkg from '../package.json' with { type: 'json' }

const jsrPath = `${import.meta.dirname}/../jsr.json`
const jsr = structuredClone(jsrOriginal)

jsr.version = pkg.version
jsr.exports = pkg.exports

// oxlint-disable-next-line rules/no-effect-runtime-run -- Package sync script is a top-level executable boundary.
await Effect.runPromise(
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.writeFileString(jsrPath, `${JSON.stringify(jsr, null, 2)}\n`)
  }).pipe(Effect.provide(NodeServices.layer)),
)
