# MoonBit Code Analysis

> Document type: concrete MoonBit implementation guidance based on the official MoonBit toolchain documentation.

## Semantic navigation

Use `moon ide` for symbol-aware navigation because it uses the compiler's semantic knowledge of the project. Use text search for filenames, string literals, comments, and broad discovery; do not rely on text matches alone when locating definitions or determining every reference to a symbol.

## Investigation sequence

1. Run `moon ide outline <path/to/file_or_directory>` to understand the file or package structure before reading implementation details.
2. Run `moon ide doc '<query>'` to discover packages, types, methods, and their documentation.
3. Run `moon ide peek-def <symbol>` to inspect a definition. Add `-loc filename:line[:col]` when the name is ambiguous in local context.
4. Run `moon ide find-references <symbol>` before renaming a symbol, changing its signature, or modifying an invariant used by callers. The command performs a global search and does not currently accept `-loc`.
5. Run the relevant repository `mbt:check` or package `check` task after the change; semantic navigation does not replace compilation and project checks.

## Sources

- [Official MoonBit Agent IDE documentation](https://docs.moonbitlang.com/en/latest/toolchain/moonide/index.html)
- [Generated MoonBit Agent IDE reference](../../docs-moonbit/references/toolchain-moonide-index.md)
