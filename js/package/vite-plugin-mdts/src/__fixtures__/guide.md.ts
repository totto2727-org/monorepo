import { defineNote, md, noteBody, noteRef } from 'vite-plugin-mdts'
import type { MarkdownMetadata } from 'vite-plugin-mdts'
import reference from './reference/api.md.ts?text=Details&hash=api&link'

const notes = defineNote([
  {
    body: md`The link text and this definition share one typed slug.`,
    slug: 'reference-link',
  },
] as const)

export const meta = {
  frontmatter: {
    description: 'Generated from TypeScript metadata.',
    tags: ['markdown', 'typescript'],
    draft: false,
    metadata: { version: '1.0' },
  },
  title: 'Guide',
} satisfies MarkdownMetadata

export default md`${reference}${noteRef(notes, 'reference-link')}

${noteBody(notes, 'reference-link')}
`
