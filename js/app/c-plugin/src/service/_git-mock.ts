import { Effect, FileSystem } from 'effect'

class GitError extends Error {
  override name = 'GitError'
  _tag = 'GitError' as const
}

const mockClone = (_url: string, dest: string) =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.makeDirectory(dest, { recursive: true })
  })

export const gitMock = {
  GitError,
  checkInstalled: Effect.void,
  checkout: () => Effect.void,
  clone: mockClone,
  pull: () => Effect.void,
  revParseHead: () => Effect.succeed('mock-commit-hash'),
}
