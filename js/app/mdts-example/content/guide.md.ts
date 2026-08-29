import { md } from 'mdts'

import markdownSyntax from './markdown-syntax.md.ts?link'
import reference from './reference/api.md.ts?link'
import skill from './SKILL.md.ts?link'

export const meta = { title: 'Guide' }

export default md`This document is generated from a TypeScript module during a Vite build.

## Related documents

${markdownSyntax}

${reference}

${skill}
`
