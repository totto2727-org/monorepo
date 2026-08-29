import { md } from 'vite-plugin-markdown'
import reference from './reference.md.ts?link'

export const meta = { title: 'Guide' }

export default md`# Guide

${reference}
`
