---
name: deno-cli-tool
description: >-
  This skill should be used when creating single-file CLI tools with Deno and TypeScript.
  Relevant when the user asks to build a CLI tool, create a command-line utility,
  or set up argument parsing with Effect CLI.
  Common triggers: "create CLI tool", "build command-line app", "deno CLI",
  "Effect CLI", "argument parsing".
---

# Deno CLI Tool

Rules for building single-file CLI tools with Deno.
For general scripting rules (imports, built-in API preference, prohibited technologies), see [script-rules](../script-rules/SKILL.md).

## Core Principles

1. **Single file** — one `.ts` file unless explicitly told otherwise
2. **Executable via shebang** — include permissions in shebang, install with `chmod +x`
3. **No build step** — Deno runs TypeScript directly

## Tech Stack

### Argument Parsing (REQUIRED: Effect CLI)

Always use Effect CLI for argument parsing:

| Purpose       | Package                 | Registry                                     |
| ------------- | ----------------------- | -------------------------------------------- |
| CLI framework | `@effect/cli`           | `jsr:@totto2727/fp@3.0/effect/cli`           |
| Core / Schema | `effect`                | `jsr:@totto2727/fp@3.0/effect`               |
| HTTP client   | `@effect/platform`      | `jsr:@totto2727/fp@3.0/effect/platform`      |
| Node runtime  | `@effect/platform-node` | `jsr:@totto2727/fp@3.0/effect/platform/node` |

### Other Libraries

| Purpose          | Package     | Registry        |
| ---------------- | ----------- | --------------- |
| Terminal spinner | `ora`       | `npm:ora`       |
| Terminal colors  | `ansis`     | `npm:ansis`     |
| YAML parsing     | `@std/yaml` | `jsr:@std/yaml` |
| Path utilities   | `@std/path` | `jsr:@std/path` |

## Shebang

Only request the minimum permissions needed:

```typescript
#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net
```

Common flags: `--allow-read`, `--allow-write`, `--allow-net`, `--allow-env`, `--allow-run`, `--allow-ffi`

## Setup

```bash
chmod +x my-tool.ts
```

## Effect CLI Basic Pattern

A minimal Effect CLI tool with a single command:

```typescript
#!/usr/bin/env -S deno run --allow-read
import { Console, Effect } from 'jsr:@totto2727/fp@3.0/effect'
import { Args, Command } from 'jsr:@totto2727/fp@3.0/effect/cli'
import { NodeContext, NodeRuntime } from 'jsr:@totto2727/fp@3.0/effect/platform/node'
import * as process from 'node:process'

const name = Args.text({ name: 'name' })

const main = Command.make('greet', { name }, ({ name }) => Console.log(`Hello, ${name}!`))

const cli = Command.run(main, { name: 'greet', version: '0.1.0' })

cli(process.argv).pipe(Effect.provide(NodeContext.layer), NodeRuntime.runMain)
```

## Template

- [templates/effect.ts](./templates/effect.ts) — Effect CLI with subcommands, HTTP client, schema validation

## Reference

- [reference/c7.ts](./reference/c7.ts) — production example (Context7 CLI client using Effect)
