import { writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

// eslint-disable-next-line import/no-relative-parent-imports
import jsrOriginal from '../jsr.json' with { type: 'json' }
// eslint-disable-next-line import/no-relative-parent-imports
import pkg from '../package.json' with { type: 'json' }

const jsrPath = resolve(import.meta.dirname, '..', 'jsr.json')
const jsr = structuredClone(jsrOriginal)

jsr.version = pkg.version
jsr.exports = pkg.exports

// eslint-disable-next-line jest/require-hook
writeFileSync(jsrPath, `${JSON.stringify(jsr, null, 2)}\n`)
