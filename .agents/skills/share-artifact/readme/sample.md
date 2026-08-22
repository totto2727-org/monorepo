# moonbit-fib

A small MoonBit Fibonacci library for applications that need an integer sequence primitive.

## Usage

Calculate the Fibonacci number at position 10 and verify the library returns 55.

```moonbit
test "fib usage" {
  inspect(@fib.fib(10), content="55")
}
```

## Key features

- Small public API

- Supports non-negative `Int` positions on MoonBit targets

## Prerequisites

- **MoonBit project**: Use a project that can consume packages from Mooncakes.

## Setup

1. Add the package to the consuming project.

```bash
moon add example/moonbit-fib
```

2. Import the package in the consuming package's `moon.pkg`.

```text
import {
  "example/moonbit-fib" @fib
}
```

## API

### `fib`

Returns the Fibonacci number at the requested zero-based position.

Callers must pass a non-negative position; negative positions are outside the supported input range.

```moonbit
test "fib usage" {
  inspect(@fib.fib(10), content="55")
}
```

## Development

For project structure and development commands, see [AGENTS.md](./AGENTS.md).

## License

MIT

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
