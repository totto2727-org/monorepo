# Rust CLI — UI Layer Details (Lightweight CLI / Advanced Declarative UI)

Organize the UI embedded in a CLI into two layers:

- **Lightweight CLI**: Input acceptance + progress display + log output only. Directly combine standalone crate features.
- **Advanced Declarative UI**: Full-screen dashboards, multi-screen navigation, large-scale state management. Built with `tui-realm`.

Intermediate options that are "declarative but lightweight" (e.g., React-style TUI frameworks) are not adopted in this skill.

## Layer Overview

| Layer                   | Use Case                                                                  | Recommended                                                                                      | Features                                                                                          |
| ----------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Lightweight CLI         | Argument parsing, prompts, progress bars / spinners, log output, coloring | Combination of `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + standard `println!` | Each crate has a thin independent responsibility, called directly as needed. Not framework-based. |
| Advanced Declarative UI | Full-screen dashboards, multi-screen navigation                           | `tui-realm`                                                                                      | Elm Architecture with Component + Message/Update                                                  |

The criterion for choosing between them is **whether the UI itself becomes complex as a state machine**.
If you only need to stream input + logs, stop at the lightweight CLI (`tui-realm` is overkill for simple I/O).

## Lightweight CLI: `clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + standard `println!`

Each is a small, single-responsibility crate, combined by calling them directly where needed in the CLI. It is _not_ a "TUI framework".

### Role Distribution

| Crate / Feature                   | Role                                                              | Typical Invocation Example                                   |
| --------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------ |
| `clap`                            | Argument / subcommand / env                                       | `Cli::parse()` (declarative flags via `derive`)              |
| `tracing`                         | **Structured logging** (machine-readable)                         | `tracing::info!(...)` + `tracing_subscriber::fmt()` init     |
| Standard `println!` / `eprintln!` | **Simple stdout / stderr** (human-readable / inter-process pipes) | `println!("...")` / `eprintln!("...")`                       |
| `owo-colors`                      | **Coloring** (decorative output)                                  | `"warning".yellow()` / `"ok".green()` (`OwoColorize` trait)  |
| `inquire`                         | One-shot prompts                                                  | `Select::new(...).prompt()?` / `Confirm::new(...).prompt()?` |
| `indicatif`                       | Progress bars / spinners                                          | `ProgressBar::new(n)` / `ProgressBar::new_spinner()`         |

#### Output Responsibility Sharing Principle

- **Structured logging (`tracing`)**: Events that require machine readability / monitoring / post-hoc analysis. Use `tracing_subscriber` to centrally configure the output destination, format, and filter.
- **Simple stdout / stderr (standard features)**: Primary command output (data piped to downstream stages as upstream) or one-shot text for the user.
- **Coloring (`owo-colors`)**: A dedicated layer that adds visual emphasis to the above outputs. An independent responsibility from `tracing` filter / `println!` usage.

### `clap` (Argument Parser)

Declare using `derive` macros on `struct` / `enum` bases. `#[arg(env = "...")]` can express env fallback. Subcommands are split via `#[derive(Subcommand)]` enum. See [../templates/main.rs](../templates/main.rs) for a template.

### `tracing` (Structured Logging)

Embed `tracing::info!` / `warn!` / `error!` and initialize `tracing_subscriber::fmt()` (or `tracing_subscriber::registry()` with composite layers) at `main` startup. Switch formatting via `with_env_filter(EnvFilter::try_from_default_env()...)` controlled by the `RUST_LOG` environment variable. Use **exclusively for machine-readable structured logging** (use standard `println!` for simple human-readable stdout or primary CLI output).

### Standard `println!` / `eprintln!` (stdout / stderr)

Use standard features directly without external crates for primary CLI output (command execution results) or one-shot text output. Use `eprintln!` for stderr. The principle: data to be piped to downstream stages goes to stdout via `println!`; progress / messages go to stderr via `eprintln!`.

### `owo-colors` (Coloring)

By `use`-ing the `OwoColorize` trait, methods like `.green()` / `.yellow()` / `.bold()` become available on any `Display` implementation. A dedicated decorative layer for adding color to `tracing` formatter or `println!` output. Color activation (using `atty` / `NO_COLOR` env var) can be suppressed via `if_supports_color()`.

### `inquire` (Prompts)

Provided widgets: `Select`, `MultiSelect`, `Text`, `Password`, `Confirm`, `Editor`, `DateSelect`, `CustomType`, Select with autocomplete. Validation, paging, and tab completion are built-in. Call only where a prompt is displayed.

### `indicatif` (Progress / Spinners)

- `ProgressBar::new_spinner()` for a waiting spinner, `ProgressBar::new(n)` for a bounded progress bar.
- `MultiProgress` for multiple concurrent bars.
- `set_style(ProgressStyle::with_template(...))` for template string configuration.
- When used with `tracing`, they can coexist via `indicatif-log-bridge` or similar. However, this skill separates usage by purpose: progression via indicatif, logging via tracing. If necessary, write to stderr via `pb.println("...")`.

### Example of Combined Usage Pattern

```text
Receive arguments with clap
  → Interactively confirm default values with inquire
  → Start indicatif spinner
  → Asynchronous processing (tokio + reqwest, etc.)
  → Summarize log with tracing::info! (structured log, stderr / any subscriber output destination)
  → Finish indicatif spinner
  → Write result (fetched data / formatted output) to stdout with println!
    (so it can be piped to downstream). Output human-readable messages to stderr with eprintln!,
    use owo-colors for emphasis where needed (`.green()` / `.bold()`, etc.)
```

If you can complete the task within this layer, do not bring in `tui-realm`.

### Exception: Partial Adoption of `tui-realm` for Complex Final Output

While building everything as a lightweight CLI, the final output may require complex tables / multi-column lists / structured views. In such cases, **partial adoption is allowed**: call `tui-realm` only for that output part (no need to switch the entire UI to `tui-realm`).

- Conditions: The output is complex enough that simple line-based `println!` formatting is hard to read (many columns / cell width adjustment needed / filtering needed, etc.)
- Scope: Create a `tui-realm` Component only for the function that renders the final output and call it; everything else (argument parsing, progression, logging) continues using the lightweight CLI stack.
- Distinction: If looping screen transitions or input event-driven behavior is needed, consider switching to "Advanced Declarative UI" mode instead of partial adoption.

## Advanced Declarative UI: `tui-realm`

A TUI framework with state management combining React + Elm (the name "Realm" is a portmanteau of React and Elm). It internally uses `ratatui` as the underlying drawing library, but this skill uses only the `tui-realm` API in principle (designs that directly use `ratatui` are not adopted).

### Components

- **Component**: Reusable UI parts (with props / state)
- **Application**: Bundles Components
- **Update / Message**: Message-driven equivalent of Elm's Update function
- **Event**: Input events

### Adoption Conditions

Consider this layer when any of the following apply:

- Full-screen dashboard or multi-pane layout is needed
- Large-scale state machine is needed for screen transitions, wizards, etc.
- Input events and rendering need to loop

Do not adopt if the lightweight CLI suffices (over-engineering).

## Selection Guideline (Flowchart-like)

1. Argument reception + log streaming + one-shot prompts + progress bars / spinners + colored output sufficient?
   → **Lightweight CLI** (`clap` + `tracing` + `inquire` + `indicatif` + `owo-colors` + standard `println!`)
2. Full-screen / multi-screen / large-scale state management needed?
   → **Advanced Declarative UI** (`tui-realm`)

If in doubt, start with the lightweight CLI and switch to `tui-realm` only when UI state management grows too large.

## Related Resources

- [clap](https://github.com/clap-rs/clap)
- [tracing](https://github.com/tokio-rs/tracing)
- [owo-colors](https://github.com/jam1garner/owo-colors)
- [inquire](https://github.com/mikaelmello/inquire)
- [indicatif](https://github.com/console-rs/indicatif)
- [tui-realm](https://github.com/veeso/tui-realm)
