<!-- Illustrative README for a hypothetical package, not a published dependency or verified product example. -->

# moonbit-fib

A small MoonBit Fibonacci library for applications that need an integer sequence primitive.

## Usage

Calculate the Fibonacci number at position 10 and verify the library returns 55.

```mbt check
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

```bash
moon add example/moonbit-fib
```

```text
import {
  "example/moonbit-fib" @fib
}
```

## API

### `fib`

Returns the Fibonacci number at the requested zero-based position.

Callers must pass a non-negative position; negative positions are outside the supported input range.

```mbt check
test "fib API usage" {
  inspect(@fib.fib(7), content="13")
}
```

## Development

For project structure and development commands, see [AGENTS.md](../agents/sample.md).

## License

MIT
