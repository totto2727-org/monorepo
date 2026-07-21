# @totto2727/fp Installation

> Document type: concrete package setup guidance.

A TypeScript functional programming utility library that provides unified re-exports and bridge modules for Effect, option-t, and other FP libraries.

## Installation

`effect@beta` is a required peer dependency and must be installed alongside `@totto2727/fp`.

### Node.js

```bash
bun add jsr:@totto2727/fp effect@beta
```

### Deno

```bash
# Add to deno.json
deno add jsr:@totto2727/fp npm:effect@beta
```

```ts
// Direct import (without deno.json)
import { Result } from 'jsr:@totto2727/fp@<version>/option-t'
```
