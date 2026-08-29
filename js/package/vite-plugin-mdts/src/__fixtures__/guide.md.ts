import { md } from 'vite-plugin-mdts'
import type { MarkdownMetadata } from 'vite-plugin-mdts'
import reference from './reference/api.md.ts?text=Details&hash=api&link'

export const meta = {
  frontmatter: {
    description: 'Generated from TypeScript metadata.',
    tags: ['markdown', 'typescript'],
    draft: false,
    metadata: { version: '1.0' },
  },
  title: 'Guide',
} satisfies MarkdownMetadata

export default md`${reference}
`
