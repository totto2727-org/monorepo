# MoonBit CLI Antipatterns

> Document type: concrete MoonBit CLI implementation guidance.

## Anti-patterns

- Importing or constructing `@argparse.Command` in an Admiral-based CLI.
- Calling `parse()` or manually matching subcommands in `main.mbt`.
- Wrapping async command execution in a task group or background spawn.
- Reimplementing root or subcommand help fallback around `app.run()`.
- Using synchronous command callbacks; `run` callbacks are async by default.
- Directly constructing request JSON from `@admiral.Context`.
- Reading raw `@admiral.Context` outside command-local options conversion and the async command entrypoint that invokes it.
- Shared generic body builders like `add_bool_nested` or `add_string_nested`.
- Keeping mutually exclusive states as several optional fields in `Options`.
- Resolving environment variables in the runner instead of options conversion.
- Parsing files or domain payloads while creating the options struct.
- Using `derive(ToJson)` for request body wire types.
- Using `Map[String, Json]` as the default JSON construction strategy.
- Replacing explicit required-value handling or meaningful fallback chains with opaque error-extraction helpers.
- Destructuring required option arrays with `[value, ..]` after extraction.
- Adding aliases (`#alias` or type aliases) unless the alternate name is actually part of the public API and used by callers.
