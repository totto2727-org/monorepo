import { md } from 'vite-plugin-markdown'
import reference from './reference/api.md.ts?text=Details&hash=api&link'

export const meta = { title: 'Guide' }

export default md`# Guide

${reference}
`
