import { defineMeta, defineNote, md, noteBody, noteRef } from 'vite-plugin-mdts'
import type { MarkdownLinkReference, MarkdownTemplate } from 'vite-plugin-mdts'
import reference from './reference/api.md.ts?text=Details&hash=api&link'

const notes = defineNote([
  {
    body: md`The link text and this definition share one typed slug.`,
    slug: 'reference-link',
  },
] as const)

const description = (): string => 'Generated from runtime TypeScript metadata.'

const renderReference = (link: MarkdownLinkReference): MarkdownTemplate =>
  md`${link}${noteRef(notes, 'reference-link')}`

export const meta = defineMeta({
  frontmatter: {
    description: description(),
    tags: ['markdown', 'typescript'],
    draft: false,
    metadata: { version: '1.0' },
  },
  title: ['Gu', 'ide'].join(''),
})

export default md`
${renderReference(reference)}

${noteBody(notes, 'reference-link')}
`
