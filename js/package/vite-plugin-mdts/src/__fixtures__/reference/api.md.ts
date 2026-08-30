import { defineMeta, md } from 'vite-plugin-mdts'

import guide from '../guide.md.ts?link'

export const meta = defineMeta({ title: 'Reference' })

export default md`Back to ${guide}.`
