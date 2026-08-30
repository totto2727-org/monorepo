import { md } from 'mdts'

export const meta = { title: 'Knip orphan validation' }

export default md`
This nested document is not imported by an entry document.

It verifies that \`mdts lint\` reports unreachable Markdown source files.
`
