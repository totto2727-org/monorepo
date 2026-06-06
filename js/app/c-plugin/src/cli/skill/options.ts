import * as Os from 'node:os'

import { Flag } from 'effect/unstable/cli'

export const searchTopDirOption = Flag.directory('search-top-dir', { mustExist: true }).pipe(
  Flag.withDefault(Os.homedir()),
)
