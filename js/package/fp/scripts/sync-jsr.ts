import { writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

import jsrOriginal from '../jsr.json' with { type: 'json' }
import pkg from '../package.json' with { type: 'json' }

const jsrPath = resolve(import.meta.dirname, '..', 'jsr.json')
const jsr = structuredClone(jsrOriginal)

jsr.version = pkg.version
jsr.exports = pkg.exports

writeFileSync(jsrPath, `${JSON.stringify(jsr, null, 2)}\n`)
