import { md } from 'mdts'

export const meta = {
  title: 'Lint target',
}

export default md`This forbidden sentence is intentionally longer than one hundred and fifty characters so markdownlint and textlint both report the generated Markdown while mdts maps diagnostics back to this source line.
`
