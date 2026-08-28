import { md } from 'vite-plugin-markdown'

const features = ['TypeScript interpolation', 'Vite asset emission', 'Exact Markdown source preservation']
const featureList = features.map((feature) => `- ${feature}`).join('\n')

export const guide = md`# Vite Markdown Plugin Example

This document is generated from a TypeScript module during a Vite build.

## Features

${featureList}

## Build

Run \`vp run --filter vite-plugin-markdown-example build\` from the repository root.
`
