import { ok3 } from 'package-name'
import { ok4 } from 'package.js'

import { ok5 } from '##storybook/utils'
import { qux } from '#/qux.jsx'
import { baz } from '#@/baz.js'

import { bar } from '../bar.jsx'
import { ok2 } from '../ok.tsx'
import { foo } from './foo.js'
// These should NOT be flagged
import { ok1 } from './ok.ts'

export * from './reexport.js'
export { named } from '../named.jsx'
