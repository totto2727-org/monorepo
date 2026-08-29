#!/usr/bin/env node

import { parseArgs } from 'node:util'

import { Predicate } from 'effect'

import { buildMarkdown } from './build.ts'
import { createMarkdownPreview } from './preview.ts'

const help = `mdts

Usage:
  mdts build [--config <file>]
  mdts preview [--config <file>]
`

const main = async (): Promise<void> => {
  const [command, ...args] = process.argv.slice(2)
  if (Predicate.isNullish(command) || command === '--help' || command === '-h') {
    process.stdout.write(help)
    return
  }

  const parsed = parseArgs({
    allowPositionals: false,
    args,
    options: {
      config: { short: 'c', type: 'string' },
      help: { short: 'h', type: 'boolean' },
    },
    strict: true,
  })
  if (parsed.values.help === true) {
    process.stdout.write(help)
    return
  }

  const options = {
    configFile: parsed.values.config,
    root: process.cwd(),
  }

  if (command === 'build') {
    await buildMarkdown(options)
    return
  }

  if (command === 'preview') {
    const server = await createMarkdownPreview(options)
    await server.listen()
    server.printUrls()
    server.bindCLIShortcuts({ print: true })
    return
  }

  throw new TypeError(`unknown mdts command: ${command}`)
}

await main()
