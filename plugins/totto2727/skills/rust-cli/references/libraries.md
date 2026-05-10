# Rust CLI Libraries — JS/Effect ↔ Rust Complete Mapping Table

Recommended crates by feature category when implementing a CLI in asynchronous Rust.
Corresponding JS/Effect items are listed side by side to clarify the migration path.

## How to read the table

- **Recommended**: The crate to adopt (this skill narrows down candidates; no alternatives are listed)
- Assumes asynchronous (tokio). For synchronous versions, refer to each crate's blocking feature

## Core (required categories)

| Feature                       | Use case                      | JS / Effect side                                          | Rust (recommended)                                                                 |
| ----------------------------- | ----------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Runtime                       | task / concurrent I/O         | `@effect/platform-node` `NodeRuntime` + `Effect.gen`      | `tokio` (`full` features)                                                          |
| Argument parsing              | subcommands / flags / help    | `effect/unstable/cli` (`Command`/`Flag`)                  | `clap` (`derive`)                                                                  |
| HTTP client                   | REST API (JSON/binary/header) | `effect/unstable/http` (`HttpClient` + `FetchHttpClient`) | `reqwest` (`json` + `rustls-tls`)                                                  |
| JSON                          | parse / stringify             | `JSON.*`                                                  | `serde` + `serde_json`                                                             |
| Schema validation             | unknown value → type check    | `effect` `Schema.decodeUnknownEffect`                     | `serde` derive (type match) + `garde` (value range)                                |
| Error type definition         | tagged errors                 | `Data.TaggedError`                                        | `thiserror` + `miette` (`Diagnostic` derive combined)                              |
| Error aggregation (app layer) | `?` propagation + context     | `Effect` chain                                            | `miette::Result<T>` (= `Result<T, miette::Report>`) + `IntoDiagnostic` / `WrapErr` |
| Error diagnostic report       | help / labels / source-spans  | (hand-written format)                                     | `miette` (`#[diagnostic(code, help, ...)]` + `fancy` feature)                      |
| Option / Result               | nullable / failure            | `Option`, `Effect`                                        | Standard `Option<T>` / `Result<T, E>`                                              |

## I/O / OS

| Feature              | Use case                            | JS / Effect side                            | Rust (recommended)                        | Notes                                                                                                                                                          |
| -------------------- | ----------------------------------- | ------------------------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Async file           | read/write/mkdir/rm                 | `node:fs/promises`                          | `tokio::fs`                               | —                                                                                                                                                              |
| Path                 | join / relative / dirname           | `node:path`                                 | `camino` (`Utf8Path` / `Utf8PathBuf`)     | UTF-8-only wrapper for `std::path::Path`. `.as_str()` never returns `Option` / serde serializes stably as plain string / works as HashMap keys for JSON output |
| Symlink              | create / detect                     | `Fs.symlink`, `lstat().isSymbolicLink()`    | `tokio::fs::symlink` + `symlink_metadata` | On Windows you must choose `std::os::windows::fs::symlink_dir/file`                                                                                            |
| Child process        | call external commands like `git`   | Node `child_process` execFile (promisified) | `tokio::process::Command`                 | Offload sync work via `tokio::task::spawn_blocking`                                                                                                            |
| Environment variable | get API token                       | `process.env`                               | Standard `std::env::var`                  | —                                                                                                                                                              |
| Temp file            | test fixture                        | (hand-written)                              | `camino-tempfile`                         | UTF-8 wrapper for `tempfile` (`NamedUtf8TempFile` / `Utf8TempDir`), auto-cleanup via RAII                                                                      |
| File lock            | prevent concurrent lock-file writes | (hand-written)                              | `fd-lock`                                 | —                                                                                                                                                              |

## Concurrency / Parallelism

| Feature              | Use case            | JS / Effect side                           | Rust (recommended)                      |
| -------------------- | ------------------- | ------------------------------------------ | --------------------------------------- |
| Unbounded concurrent | parallel I/O        | `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`             |
| Bounded concurrent   | limit to n parallel | `Effect.all({ concurrency: n })`           | `stream::iter(...).buffer_unordered(n)` |
| Panic-safe spawn     | error isolation     | —                                          | `tokio::task::JoinSet`                  |

## Data / Format

| Feature               | Use case                  | JS / Effect side                      | Rust (recommended)      |
| --------------------- | ------------------------- | ------------------------------------- | ----------------------- |
| YAML                  | frontmatter, config       | (not currently used)                  | `serde_yml`             |
| TOML                  | config                    | (not currently used)                  | `toml`                  |
| Config (multi-source) | env + file + CLI merge    | `JSON.parse(readFile)` + manual merge | `figment`               |
| Date / time           | TZ-aware datetime         | `Date`, `effect` DateTime             | `jiff`                  |
| Glob                  | pattern matching          | (hand-written)                        | `globset`               |
| File walk             | gitignore-respecting walk | manual recursion + `SKIP_DIRS`        | `ignore` (from ripgrep) |
| Diff                  | dry-run preview           | (hand-written)                        | `similar`               |

## Observability / Output

| Feature            | Use case             | JS / Effect side | Rust (recommended)                |
| ------------------ | -------------------- | ---------------- | --------------------------------- |
| Structured logging | hierarchical logging | `Effect.log`     | `tracing` + `tracing-subscriber`  |
| Simple stdout      | debug output         | `Console.log`    | Standard `println!` / `eprintln!` |
| Coloring           | styled output        | (none currently) | `owo-colors`                      |

## UI Layer (lightweight CLI / advanced declarative UI — two options)

See also [tui.md](./tui.md).

| Layer                            | Use case                                       | Recommended |
| -------------------------------- | ---------------------------------------------- | ----------- |
| Lightweight (prompt)             | select / input / confirm / password            | `inquire`   |
| Lightweight (progress / spinner) | progress bar / waiting indicator               | `indicatif` |
| Advanced declarative UI          | fullscreen dashboard / multi-screen navigation | `tui-realm` |

The lightweight CLI side **combines `clap` + `tracing` + `inquire` + `indicatif` as independent utility crates**. If that suffices, do not bring in `tui-realm` (overkill).

## Version control / Git

| Feature        | Use case                        | JS / Effect side              | Rust (recommended)                                    |
| -------------- | ------------------------------- | ----------------------------- | ----------------------------------------------------- |
| Git operations | clone / pull / fetch / checkout | Node execFile driving git CLI | `tokio::process::Command` driving git (shortest path) |

## Testing

| Feature            | Use case                     | JS / Effect side | Rust (recommended)                    |
| ------------------ | ---------------------------- | ---------------- | ------------------------------------- |
| Unit test          | normal tests                 | Vitest           | Standard `#[test]` / `#[tokio::test]` |
| Display comparison | assertion diff               | Vitest           | `pretty_assertions`                   |
| Snapshot           | structured output comparison | (not used)       | `insta`                               |
| HTTP mock          | API mock                     | (hand-written)   | `mockito`                             |
| Temp dir           | fs test fixture              | (hand-written)   | `camino-tempfile`                     |

## Migration quick reference

From JS/Effect idioms to Rust idioms:

| JS / Effect                                | Rust                                                                                |
| ------------------------------------------ | ----------------------------------------------------------------------------------- |
| `Effect.gen(function*() { yield* x })`     | `async fn { x.await }`                                                              |
| `Effect.tryPromise({ try, catch })`        | `?` operator + `thiserror` `#[from]` (external crate errors → `.into_diagnostic()`) |
| `Effect.all({ concurrency: 'unbounded' })` | `futures::future::join_all`                                                         |
| `Option.isSome(x) ? x.value : default`     | `x.unwrap_or(default)`                                                              |
| `Schema.decodeUnknownEffect(T)(input)`     | `serde_json::from_value::<T>(input)?`                                               |
| `Data.TaggedError('Foo')<{...}>`           | `#[derive(thiserror::Error, miette::Diagnostic)] enum FooError { ... }`             |
| `process.env.X ?? flag`                    | `clap` `#[arg(env = "X")]`                                                          |
| `Console.log(...)`                         | `println!("{...}", ...)`                                                            |
| `Effect.log(...)`                          | `tracing::info!(...)`                                                               |
