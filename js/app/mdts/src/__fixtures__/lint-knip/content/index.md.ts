import { md } from '../../../config.ts'

import linked from './nested/linked.md.ts?link'

export const meta = { title: 'Index' }

export default md`Read ${linked}.`
