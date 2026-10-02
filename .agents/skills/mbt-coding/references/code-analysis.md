# MoonBit Code Analysis

> Document type: concrete MoonBit implementation guidance based on the official MoonBit toolchain documentation.

## Semantic navigation

Use `moon ide` for symbol-aware navigation because it uses the compiler's semantic knowledge of the project. Use text search for filenames, string literals, comments, and broad discovery; do not rely on text matches alone when locating definitions or determining every reference to a symbol.

## Choose by investigation need

These commands are alternatives for different questions, not a checklist before every edit.

| Question                                                                       | Command                                                                                       |
| ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| What declarations are in an unfamiliar file or package?                        | `moon ide outline <path/to/file_or_directory>`                                                |
| Which package, type, or method provides this API?                              | `moon ide doc '<query>'`                                                                      |
| Where is this symbol defined?                                                  | `moon ide peek-def <symbol>`; add `-loc filename:line[:col]` when local context is ambiguous. |
| Which callers are affected by a rename, signature change, or shared invariant? | `moon ide find-references <symbol>`; this global search does not currently accept `-loc`.     |

Check references before changes that affect callers.
A local comment or spelling fix does not require every semantic query.
For code changes, run the relevant repository `mbt:check` or package `check` task; semantic navigation does not replace compilation and project checks.

## Sources

- Use the official `$moonbit-orientation` skill locally when installed for source selection and freshness checks.
- [Official MoonBit Agent IDE documentation](https://docs.moonbitlang.com/en/latest/toolchain/moonide/index.html)

If `$moonbit-orientation` is unavailable, fetch the [official documentation Markdown source index](https://raw.githubusercontent.com/moonbitlang/moonbit-docs/main/next/index.md) directly. For source links beginning with `/`, strip the leading slash and resolve the path under `https://raw.githubusercontent.com/moonbitlang/moonbit-docs/main/next/`.
