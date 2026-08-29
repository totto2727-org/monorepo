import { md } from 'vite-plugin-mdts'

import apiReference from './reference/api.md.ts?link'

export const meta = {
  title: 'Guide',
}

export default md`# Guide

Read the ${apiReference}.
`
