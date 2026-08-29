import { md } from 'vite-plugin-mdts'

import reference from './reference/api.md.ts?link'

export const meta = { title: 'Guide' }

export default md`# Guide

This document is generated from a TypeScript module during a Vite build.

## Related document

${reference}
`
