import { md } from 'vite-plugin-mdts'
import type { MarkdownMetadata } from 'vite-plugin-mdts'

export const meta = {
  frontmatter: {
    name: 'preview-plugins',
    description: 'Verifies frontmatter and configured Comark plugins in preview.',
    'allowed-tools': 'Read',
  },
  title: 'Preview plugins',
} satisfies MarkdownMetadata

export default md`Configured plugins are rendered in the preview.[^preview]

[^preview]: This footnote is enabled through mdts.config.ts.

> [!WARNING]
  Alerts use GitHub-compatible markup and styles.
`
