import { defineMeta, md } from 'vite-plugin-mdts'

export const meta = defineMeta({ title: 'Trailing newline' })

export default md`
   Body.   
   
`
