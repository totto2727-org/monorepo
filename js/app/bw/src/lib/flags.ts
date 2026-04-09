import { Flag } from 'effect/unstable/cli'

export const accountId = Flag.string('account-id').pipe(Flag.optional)

export const apiToken = Flag.string('api-token').pipe(Flag.optional)

export const url = Flag.string('url').pipe(Flag.optional)

export const html = Flag.string('html').pipe(Flag.optional, Flag.withDescription('Path to local HTML file'))

export const waitUntil = Flag.string('wait-until').pipe(
  Flag.optional,
  Flag.withDescription('Page load strategy: load, domcontentloaded, networkidle0, networkidle2'),
)

export const config = Flag.string('config').pipe(Flag.optional, Flag.withDescription('Path to JSON config file'))

export const output = Flag.string('output').pipe(
  Flag.withAlias('o'),
  Flag.optional,
  Flag.withDescription('Output file path'),
)

export const requiredOutput = Flag.string('output').pipe(Flag.withAlias('o'), Flag.withDescription('Output file path'))
