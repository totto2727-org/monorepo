import { defineNote, md, noteBody, noteRef } from 'mdts'
import type { MarkdownMetadata } from 'mdts'

const notes = defineNote([
  {
    body: md`This footnote is enabled through mdts.config.ts.`,
    slug: 'preview-plugin',
  },
] as const)

export const meta = {
  frontmatter: {
    name: 'preview-plugins',
    description: 'Verifies frontmatter and configured Comark plugins in preview.',
    'allowed-tools': 'Read',
  },
  title: 'Preview plugins',
} satisfies MarkdownMetadata

export default md`Configured plugins are rendered in the preview.${noteRef(notes, 'preview-plugin')}

${noteBody(notes, 'preview-plugin')}

> [!WARNING]
  Alerts use GitHub-compatible markup and styles.
`
