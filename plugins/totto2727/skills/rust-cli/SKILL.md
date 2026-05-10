---
name: rust-cli
description: >-
  This skill should be used when designing or implementing async CLI tools in Rust,
  selecting Rust crates for CLI work (argument parsing, HTTP, JSON/Schema, error handling,
  filesystem, dates, logging, TUI/spinner/prompt), or porting existing Effect-based / Node CLIs to Rust.
  Common triggers: "Rust CLI", "RustでCLI", "clap", "tokio", "reqwest", "tui-realm",
  "inquire", "indicatif", "ライブラリ選定", "技術選定 Rust", "Effect から Rust 移植".
  Do NOT use for: production-grade architecture review (use code-reviewer),
  generic Rust questions unrelated to CLI scope, or non-async sync-only CLI design.
metadata:
  author: totto2727
  version: 1.0.0
---

# Rust CLI — Async Rust CLI Technology Selection Map

Use Case Category: **Workflow Automation**
Design Pattern: **Context-aware Selection** (dynamically select layers based on requirements)

Provides crate selection and minimal configuration sets for implementing new async Rust CLIs / porting existing Effect-based CLIs.
The baseline assumption is the **tokio + clap + reqwest + serde** standard stack.

## Output on Skill Trigger

After hearing the user's requirements, return one or a combination of the following:

1. **Show the "Layer Quick Reference" table and the "UI Layer Selection (Lightweight CLI / Advanced Declarative UI)" table** (first response when the user is unsure)
2. **Quote the relevant category from `references/libraries.md`** (when asked for crate comparison for a specific feature)
3. **Guide to `templates/` starters** (when a project scaffold is desired)
4. **JS/Effect ↔ Rust replacement quick reference** (for porting work, see end of `references/libraries.md`)

**Do not trigger** for new Rust questions unrelated to CLI.

## Basic Policy

- **Async-first**: `tokio` is the default runtime. If synchronous processing suffices, choose the blocking variant
- **Error strategy**: Design with a single `thiserror` + `miette` stack for both library and application layers. Combine `#[derive(thiserror::Error, miette::Diagnostic)]` on each error type, and attach rich diagnostic reports with `#[diagnostic(code(...), help(...))]`. The application layer returns `miette::Result<T>`, external crate `Result`s are converted via `.into_diagnostic()`, and semantic context is accumulated with `.wrap_err(...)`
- **HTTP**: Share `reqwest::Client` as `Arc` across the process for connection reuse
- **CLI flags**: `clap` derive. Use `#[arg(env = "...")]` to declaratively express env fallback
- **UI Layer Selection (two choices)**:
  - **Lightweight CLI** (input + logging + progress display): Combine standalone feature crates: `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors`. Clearly separate output responsibilities — structured logging via `tracing`, simple stdout via standard features (`println!` / `eprintln!`), coloring via `owo-colors`. Do not bring in `tui-realm` if this suffices (overkill)
  - **Advanced Declarative UI** (multi-screen, large state, dashboards, etc.): Standardize on `tui-realm` (Elm Architecture). The underlying drawing library (`ratatui`) comes in as a transitive dependency, but implement using only `tui-realm`'s API in principle
  - **Exception (partial adoption)**: If remaining in lightweight CLI mode but only the final output is complex (tables / multi-column lists / structured views), allow partial adoption by calling `tui-realm` only for that output. No need to switch the entire UI
- **Code is deterministic, language interpretation is non-deterministic** — delegate validation and schema checks to serde/garde

## Layer Quick Reference (Required Categories Only)

| Category       | Recommended Crate                 | Notes                                                                               |
| -------------- | --------------------------------- | ----------------------------------------------------------------------------------- |
| Runtime        | `tokio` (`full`)                  | `#[tokio::main]`                                                                    |
| Argument Parsing | `clap` (`derive`)                 | Declarative env fallback and subcommands                                            |
| HTTP           | `reqwest` (`json`, `rustls-tls`)  | Share `Arc<Client>`                                                                 |
| Serialization  | `serde` + `serde_json`            | derive                                                                              |
| Schema Validation | `garde` (optional)             | serde guarantees type matching; garde handles value ranges                          |
| Error Types    | `thiserror` + `miette`            | Combine `#[derive(thiserror::Error, miette::Diagnostic)]`                           |
| Error Aggregation | `miette` (`Result` / `Report`) | Application layer: `miette::Result<T>`, external `Result`: `.into_diagnostic().wrap_err(...)` |
| File I/O       | `tokio::fs`                       | mkdir/read/write/symlink, etc.                                                      |
| Subprocess     | `tokio::process::Command`         | Shortest path for driving git CLI, etc.                                             |
| Dates          | `jiff`                            | TZ-aware/DST safe (chrono is legacy)                                                |
| Logging        | `tracing` + `tracing-subscriber`  | Not needed if occasional `println!` suffices                                        |

See [references/libraries.md](./references/libraries.md) for details — **complete correspondence table** with JS/Effect side (FS/Path/Concurrency/Testing/git/glob included).

## UI Layer Selection (Lightweight CLI / Advanced Declarative CLI)

Choose from 2 layers based on requirements. **If input + logging + progress suffice, stop at lightweight CLI** (`tui-realm` is overkill).

| Layer                   | Use Case                                                      | Recommended Stack                                                                                                                                                                                                                        |
| ----------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lightweight CLI         | Argument parsing, one-off prompts, progress bars / spinners, log output | Combine `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` as **standalone feature crates** (no framework). Clearly divide output responsibilities: **log=`tracing` / stdout=standard features / coloring=`owo-colors`** |
| Advanced Declarative UI | Full-screen dashboards, multi-screen transitions, large state management | `tui-realm` (Elm Architecture)                                                                                                                                                                                                           |

The lightweight CLI side directly calls thin, independent crates per responsibility. Only bring in `tui-realm` when the UI itself becomes complex enough to warrant a state machine.

For details and code examples, see [references/tui.md](./references/tui.md).

## Starter Templates

Start projects from templates:

- [templates/Cargo.toml](./templates/Cargo.toml) — **Comprehensive dependency set (kitchen-sink approach)** containing all recommended crates from `references/libraries.md`. Operate by **removing unnecessary crates** early in the project. Rationale: removing unnecessary items from a full set is less risky than forgetting to add something later
- [templates/main.rs](./templates/main.rs) — Minimal bootstrap example with `clap` + `tokio` + `reqwest` + `thiserror` + `miette` (only the entry-point skeleton, not an example of using every crate listed in Cargo.toml)

## Selection Decision Procedure

1. **Check if synchronous suffices** — If no concurrent I/O, the blocking variant (`reqwest::blocking`) is sufficient
2. **Decide the UI layer** — Does lightweight CLI (clap + tracing + inquire + indicatif + owo-colors + standard `println!`) suffice, or is advanced declarative UI (tui-realm) needed?
3. **Decide error design** — Use `thiserror` + `miette::Diagnostic` derive for both library and application layers; the application layer returns `miette::Result<T>` and propagates with `?`. External crate `Result`s are converted with `.into_diagnostic().wrap_err(...)`
4. **For existing Effect/Node CLI porting** — First rewrite `Option<T>` flags and env fallback using `clap` derive, which eliminates manual branching like `auth.ts`

## Troubleshooting

### Too many subcommands bloating `clap` definitions

Split with `#[derive(Subcommand)]` enum and organize into one file per submodule.
Extend the structure starting from [templates/main.rs](./templates/main.rs).

### Role separation of `thiserror` + `miette`

- **Library / Service layer**: Combine `#[derive(thiserror::Error, miette::Diagnostic)]`. `thiserror` provides a typed enum the caller can `match` on; `miette` attaches diagnostic metadata with `#[diagnostic(code(...), help(...))]`
- **Application layer / `main`**: Aggregate via `miette::Result<()>` (= `Result<(), miette::Report>`). `?` directly lifts types implementing `miette::Diagnostic`
- **External crate `Result`**: Convert to `Report` via `.into_diagnostic()` (`miette::IntoDiagnostic`), then propagate with `?`
- **Semantic context**: Attach domain information (request ID, target path, etc.) via `.wrap_err(...)` / `.wrap_err_with(|| format!("..."))` (`miette::WrapErr`)
- **Source location / backtrace**: `RUST_BACKTRACE=1` causes `miette::Report` to display a backtrace. Do not auto-inject position per `?` (policy is to semantically trace via function-level `wrap_err`)
- **End-user display**: Call `miette::set_panic_hook()` at `main` startup or enable `miette = { version = "...", features = ["fancy"] }` in `Cargo.toml` to output colorized diagnostic reports

## Trigger Examples

### Should trigger

- "I want to build an async CLI in Rust. I'd like a scaffold with clap, tokio, and reqwest."
- "I want to port an Effect-based CLI to Rust. How do I replace Schema?"
- "I want to show spinners / progress bars in a Rust CLI. Teach me how to use indicatif."
- "I want to write a full-screen dashboard in a Rust CLI. What is the tui-realm setup?"
- "I want to design error handling in a Rust CLI with miette + thiserror."

### Should NOT trigger

- "Teach me about Rust ownership." → Not a CLI context
- "I want to build an API server with Rust actix-web." → Server implementation, not CLI
- "Please review this Rust code." → `code-reviewer` responsibility
- "I want to build a CLI in Deno." → `deno-cli-tool` responsibility
- "I want to write a short Rust script that only needs synchronous processing." → Outside async CLI scope (explicit negative trigger)