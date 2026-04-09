import * as Fs from 'node:fs/promises'

import { Effect } from 'effect'

class GitError extends Error {
  _tag = 'GitError'
}

const mockClone = (_url: string, dest: string) =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: () => Fs.mkdir(dest, { recursive: true }),
  }).pipe(Effect.asVoid)

export const gitMock = {
  GitError,
  checkInstalled: Effect.void,
  checkout: () => Effect.void,
  clone: mockClone,
  pull: () => Effect.void,
  revParseHead: () => Effect.succeed('mock-commit-hash'),
}
