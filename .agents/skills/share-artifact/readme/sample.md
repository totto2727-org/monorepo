# moonbit-fib

A small MoonBit Fibonacci library for users who need a clear recursive example.

This document is canonical `README.mbt.md`; maintain `README.md` as the relative symlink `README.md -> README.mbt.md`.

## Usage

```moonbit
pub fn fib(n : Int) -> Int {
  if n < 2 { n } else { fib(n - 1) + fib(n - 2) }
}
```

## Key features

- Small public API

- Checked MoonBit example

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain.

## Setup

1. Clone the repository.

```bash
git clone https://example.com/moonbit-fib.git
```

2. Run the example.

```bash
moon run
```

## API

### `fib`

Returns the Fibonacci number at the requested zero-based position.

```moonbit
test "fib usage" {
  inspect(fib(10), content="55")
}
```

## Development

For project structure and development commands, see [AGENTS.md](./AGENTS.md).

## License

MIT

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
