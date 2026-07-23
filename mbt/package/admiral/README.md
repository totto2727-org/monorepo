# admiral

Declarative CLI builder for MoonBit, inspired by [gunshi](https://github.com/kazupon/gunshi).

This package is a fork of [mizchi/admiral](https://github.com/mizchi/admiral). It preserves the upstream MIT license and adds async-first native command execution and help fallback behavior.

A native-first wrapper around `moonbitlang/core/argparse` that provides:

- Typed option helpers (`string`, `bool`, `int`, `int64`, `uint`, `uint64`, `double`, `positional`)
- Optional configuration loading through independent config keys
- Async `run` callbacks for commands and nested subcommands
- Structured JSON schema output for AI agent integration
- Shell completion generation (bash, zsh, fish)
- Auto-generated `--help` / `--version`, including help for incomplete command paths

## Install

Add to `moon.mod`:

```moonbit
import {
  "totto2727/admiral@0.4.0",
  "moonbitlang/async@0.19.2",
}

preferred_target = "native"
```

Add to `moon.pkg`:

```moonbit
import {
  "totto2727/admiral" @admiral,
  "moonbitlang/async",
}
```

## Quick Start

```moonbit
async fn main {
  let name = @admiral.string(
    "name",
    short='n',
    description="Name to greet",
    env="ADMIRAL_NAME",
    config="name",
    required=true,
  )
  let verbose = @admiral.bool("verbose", short='v', description="Verbose output")
  let count = @admiral.int("count", short='c', description="Repeat count", default=Some(1))
  let app = @admiral.cli(
    name="myapp",
    version="1.0.0",
    description="My CLI tool",
    commands=[
      @admiral.command(
        name="greet",
        description="Greet someone",
        options=[name, verbose, count],
        examples=["myapp greet --name Alice", "myapp greet -n Bob -v -c 3"],
        run=Some(async fn(ctx) {
          let name_value = try { ctx.get_string_required(name) } catch { _ => return }
          let is_verbose = ctx.get_bool(verbose)
          let count_value = match ctx.get_int(count) { Some(n) => n; None => 1 }
          for i = 0; i < count_value; i = i + 1 {
            if is_verbose {
              println("Hello, " + name_value + "! (" + (i + 1).to_string() + ")")
            } else {
              println("Hello, " + name_value + "!")
            }
          }
        }),
      ),
    ],
  )
  app.run()
}
```

```
$ myapp greet --name Alice
Hello, Alice!

$ myapp greet -n Bob -v -c 3
Hello, Bob! (1)
Hello, Bob! (2)
Hello, Bob! (3)

$ myapp --help
Usage: myapp [command]

My CLI tool

Commands:
  greet  Greet someone

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

## Guide

### Defining Options

Options and positions use the same value types and `Context` getters:

```moonbit
// String option: --name value or -n value
@admiral.string("name", short='n', description="User name", env="MYAPP_NAME", config="name", required=true)

// Bool flag: --verbose or -v
@admiral.bool("verbose", short='v', description="Verbose output", env="MYAPP_VERBOSE", config="verbose")

// Int option: --port 8080 or -p 8080
@admiral.int("port", short='p', description="Port number", env="MYAPP_PORT", config="port", default=Some(3000))

// Scalar position: file
@admiral.position_string("file", description="Input file", config="input", required=true)

// Variadic position: file...
@admiral.position_strings("files", description="Input files")
```

`short`, `env`, and `config` are optional. Omit `short` to only allow the long form (`--name`); set `env` to read an environment variable and `config` to read a separately named configuration key.

### Environment Variables

`string`, `bool`, and `int` accept an optional `env` argument containing the environment variable name:

```moonbit
@admiral.string("name", env="MYAPP_NAME")
@admiral.bool("verbose", env="MYAPP_VERBOSE")
@admiral.int("port", env="MYAPP_PORT")
```

`app.run()` reads process arguments and the process environment by default. For tests or embedding, inject either source explicitly:

```moonbit
app.run(
  argv=Some(["serve"]),
  env={
    "MYAPP_PORT": "8080",
    "MYAPP_VERBOSE": "true",
  },
)

// An empty map prevents ambient process variables from affecting the parse.
app.run(argv=Some(["serve"]), env=Map([]))
```

Values resolve in the order `argv > env > default_values`. Environment-backed boolean flags accept `1`, `0`, `true`, `false`, `yes`, `no`, `on`, and `off`.
Precedence is defined by [`moonbitlang/core/argparse`](https://github.com/moonbitlang/core/blob/1332a066d4143511c1b7db58877bc99991f548d6/argparse/command.mbt#L97-L115).
Boolean literals are handled by its [`bool` environment parser](https://github.com/moonbitlang/core/blob/1332a066d4143511c1b7db58877bc99991f548d6/argparse/parser_values.mbt#L293-L305).
The default process map comes from [`moonbitlang/core/env`](https://mooncakes.io/docs/moonbitlang/core/env).

The generated schema contains only configured environment-variable names and config keys; it never resolves or embeds runtime values.

Each helper returns a typed, read-only definition such as `OptionDef[String]`, `OptionDef[Bool]`, or `OptionDef[Int]`.
Pass the same definition to `command` or `cli` and to the matching `Context` getter; this makes the option name a single source of truth and causes mismatched getters to fail at compile time.

### Configuration

Pass an optional argument-less `load_config` callback to `cli`.
The callback can read any configuration format, but must return a `Map[String, Json]` whose keys match the independent `config` names declared on options or positions:

```moonbit
fn load_config() -> Map[String, Json] raise @admiral.ConfigLoadFailure {
  {
    "port": (7000).to_json(),
    "verbose": (true).to_json(),
    "tags": ["release", "signed"].to_json(),
  }
}

let app = @admiral.cli(
  name="myapp",
  load_config=Some(load_config),
  commands=[...],
)
```

`CliApp::run` passes only the real environment map to `core/argparse` and stores the loaded configuration map separately in each command `Context`.
Each `Context` getter inspects the parser's [`ValueSource`](https://github.com/moonbitlang/core/blob/1332a066d4143511c1b7db58877bc99991f548d6/argparse/matches.mbt#L15-L41).
Each getter first decides whether config should be used.
An `Argv` or `Env` source skips config and continues with the existing value parsing; a `Default` or absent source first checks the definition's `config` key and decodes an available JSON value with `FromJson`, then falls back to parsing the declared default or missing-value behavior only when that config key is unavailable.

Values resolve in the order `argv > env > config > default`.
Option names, environment-variable names, and config keys are independent.
Config values are available to options and positions that declare `config`.
When a loaded config key satisfies a required argument, admiral relaxes the corresponding parser requirement; when it is absent, ordinary `core/argparse` required validation remains active.

Environment values remain scalar strings and continue to use `core/argparse` parsing.
Config values are decoded by the matching MoonBit [`FromJson`](https://github.com/moonbitlang/core/blob/1332a066d4143511c1b7db58877bc99991f548d6/json/from_json.mbt) implementation inside each getter.
Plural definitions such as `strings` and `ints` require a JSON array and preserve its elements.
An active config value that cannot be decoded raises `JsonDecodeError` instead of falling back to a declared default; scalar getters use `None` for an unavailable value, while plural getters return an empty array.
Numeric parsing failures from argv, environment variables, or declared defaults also propagate as errors instead of returning `None`.
Required plural getters return `NonEmptyArray[T]`, exposing `first: T`, `rest: ArrayView[T]`, and `all: Array[T]`; they raise when the resolved array is empty.
Return `Map([])` when no configuration values are available.

`ConfigLoadFailure` is the typed error for the callback.
For example, a loader can report `raise @admiral.ConfigLoadFailure("config file is unreadable")`.

`CliApp` is a public record.
Direct struct-literal callers must add `load_config` to `CliApp`, and direct `Context` literals must include `sources` and `config`.
Calls through `cli` remain source-compatible because `load_config` is optional.

### Reading Values from Context

Inside an async `run` callback, use `Context` methods to read parsed values:

```moonbit
let verbose = @admiral.bool("verbose")
let name = @admiral.string("name", required=true)
let port = @admiral.int("port", required=true)
let input = @admiral.position_int("input", required=true)

// Register definitions with command(options=[verbose, name, port], positionals=[input]).
run=Some(async fn(ctx) {
  // Bool — returns false if not specified
  let is_verbose = ctx.get_bool(verbose)

  // String — returns None if not specified
  let name_value = ctx.get_string(name)       // String?

  // String (required) — raises if missing
  let name_value = try { ctx.get_string_required(name) } catch { _ => return }

  // Int — parses string value to Int, returns None if missing or invalid
  let port_value = ctx.get_int(port)           // Int?

  // Int (required) — raises if missing or not a valid integer
  let port_value = try { ctx.get_int_required(port) } catch { _ => return }

  // The same getter accepts PositionDef[Int]
  let input_value = try { ctx.get_int_required(input) } catch { _ => return }
})
```

### Nested Subcommands

Commands can nest arbitrarily deep:

```moonbit
let dry_run = @admiral.bool("dry-run", description="Preview without applying")
let up_steps = @admiral.int("steps", short='s', description="Number of steps")
let down_steps = @admiral.int("steps", short='s', description="Steps to rollback", default=Some(1))
let seed_file = @admiral.string("file", short='f', description="Seed file", default=Some("seeds/default.sql"))

let app = @admiral.cli(
  name="myapp",
  commands=[
    @admiral.command(
      name="db",
      description="Database commands",
      subcommands=[
        @admiral.command(
          name="migrate",
          description="Run migrations",
          subcommands=[
            @admiral.command(
              name="up",
              description="Apply pending migrations",
              options=[dry_run, up_steps],
              examples=[
                "myapp db migrate up",
                "myapp db migrate up --dry-run",
                "myapp db migrate up --steps 5",
              ],
              run=Some(async fn(ctx) {
                if ctx.get_bool(dry_run) {
                  println("[DRY RUN] Would apply migrations")
                } else {
                  match ctx.get_int(up_steps) {
                    Some(n) => println("Applying " + n.to_string() + " migrations...")
                    None => println("Applying all pending migrations...")
                  }
                }
              }),
            ),
            @admiral.command(
              name="down",
              description="Rollback migrations",
              options=[down_steps],
              run=Some(async fn(ctx) {
                let steps = match ctx.get_int(down_steps) { Some(n) => n; None => 1 }
                println("Rolling back " + steps.to_string() + " migration(s)...")
              }),
            ),
          ],
        ),
        @admiral.command(
          name="seed",
          description="Seed the database",
          options=[seed_file],
          run=Some(async fn(ctx) {
            let file = match ctx.get_string(seed_file) { Some(f) => f; None => "seeds/default.sql" }
            println("Seeding from: " + file)
          }),
        ),
      ],
    ),
  ],
)
```

```
$ myapp db migrate up --dry-run
[DRY RUN] Would apply migrations

$ myapp db migrate down --steps 3
Rolling back 3 migration(s)...

$ myapp db seed --file custom.sql
Seeding from: custom.sql
```

### Positional Arguments

```moonbit
let files = @admiral.position_strings("files", description="Files to concatenate")

@admiral.command(
  name="cat",
  description="Concatenate files",
  positionals=[files],
  run=Some(async fn(ctx) {
    let file_values = ctx.get_strings(files)
    for file in file_values {
      println("Reading: " + file)
    }
  }),
)
```

```
$ myapp cat a.txt b.txt c.txt
Reading: a.txt
Reading: b.txt
Reading: c.txt
```

### Testing with Explicit argv

```moonbit
// In async tests, pass argv explicitly:
async test {
  app.run(argv=Some(["greet", "--name", "alice"]))
}

// In production, omit argv to use process args:
app.run()
```

### Structured Schema Output

admiral can output the full CLI definition as JSON — useful for AI agents, documentation generators, and tooling:

```moonbit
println(app.render_schema())         // -> JSON string
let json = app.render_schema_json()  // -> Json value
```

Example output:

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "description": "My CLI tool",
  "commands": {
    "greet": {
      "description": "Greet someone",
      "options": {
        "name": {
          "type": "string",
          "description": "Name to greet",
          "required": true,
          "short": "n",
          "env": "ADMIRAL_NAME"
        },
        "verbose": { "type": "bool", "description": "Verbose output", "required": false, "short": "v" },
        "count": { "type": "int", "description": "Repeat count", "required": false, "short": "c", "default": "1" }
      },
      "examples": ["myapp greet --name Alice", "myapp greet -n Bob -v -c 3"]
    },
    "db": {
      "description": "Database commands",
      "commands": {
        "migrate": {
          "description": "Run migrations",
          "commands": {
            "up": {
              "description": "Apply pending migrations",
              "options": {
                "dry-run": { "type": "bool", "description": "Preview without applying", "required": false },
                "steps": { "type": "int", "description": "Number of steps", "required": false, "short": "s" }
              },
              "examples": ["myapp db migrate up", "myapp db migrate up --dry-run"]
            }
          }
        }
      }
    }
  }
}
```

This enables AI agents to understand CLI interfaces without parsing `--help` text — types, required/optional, defaults, and examples are all machine-readable.

### Shell Completion

Generate completion scripts for bash, zsh, and fish:

```moonbit
// Bash
println(app.render_bash_completion())

// Zsh
println(app.render_zsh_completion())

// Fish
println(app.render_fish_completion())
```

Typical usage — add a `completion` subcommand:

```moonbit
let shell = @admiral.string(
  "shell",
  short='s',
  description="Shell type (bash, zsh, fish)",
  required=true,
)

@admiral.command(
  name="completion",
  description="Generate shell completion script",
  options=[shell],
  run=Some(async fn(ctx) {
    match ctx.get_string(shell) {
      Some("bash") => println(app.render_bash_completion())
      Some("zsh") => println(app.render_zsh_completion())
      Some("fish") => println(app.render_fish_completion())
      _ => println("Unsupported shell. Use: bash, zsh, fish")
    }
  }),
)
```

```bash
# Bash: add to ~/.bashrc
eval "$(myapp completion --shell bash)"

# Zsh: add to ~/.zshrc
eval "$(myapp completion --shell zsh)"

# Fish: save to completions dir
myapp completion --shell fish > ~/.config/fish/completions/myapp.fish
```

## API Reference

### Option Helpers

| Function                                                                 | Description                                     |
| ------------------------------------------------------------------------ | ----------------------------------------------- |
| `string(name, short?, description?, env?, config?, required?, default?)` | String option (`--name value`)                  |
| `strings(name, short?, description?, env?, config?, required?)`          | Repeated string option                          |
| `bool(name, short?, description?, env?, config?)`                        | Boolean flag (`--verbose`)                      |
| `int(name, short?, description?, env?, config?, required?, default?)`    | Integer option (`--port 8080`)                  |
| `ints(name, short?, description?, env?, config?, required?)`             | Repeated integer option                         |
| `int64(name, short?, description?, env?, config?, required?, default?)`  | 64-bit signed integer option                    |
| `int64s(name, short?, description?, env?, config?, required?)`           | Repeated 64-bit signed integer option           |
| `uint(name, short?, description?, env?, config?, required?, default?)`   | Unsigned integer option                         |
| `uints(name, short?, description?, env?, config?, required?)`            | Repeated unsigned integer option                |
| `uint64(name, short?, description?, env?, config?, required?, default?)` | 64-bit unsigned integer option                  |
| `uint64s(name, short?, description?, env?, config?, required?)`          | Repeated 64-bit unsigned integer option         |
| `double(name, short?, description?, env?, config?, required?, default?)` | Double-precision floating-point option          |
| `doubles(name, short?, description?, env?, config?, required?)`          | Repeated double-precision floating-point option |

### Position Helpers

| Function                                                   | Result type                                          |
| ---------------------------------------------------------- | ---------------------------------------------------- |
| `position_string(name, description?, config?, required?)`  | `PositionDef[String]`                                |
| `position_strings(name, description?, config?, required?)` | `PositionDef[Array[String]]`                         |
| `position_int(name, description?, config?, required?)`     | `PositionDef[Int]`                                   |
| `position_ints(name, description?, config?, required?)`    | `PositionDef[Array[Int]]`                            |
| `position_int64` / `position_int64s`                       | `PositionDef[Int64]` / `PositionDef[Array[Int64]]`   |
| `position_uint` / `position_uints`                         | `PositionDef[UInt]` / `PositionDef[Array[UInt]]`     |
| `position_uint64` / `position_uint64s`                     | `PositionDef[UInt64]` / `PositionDef[Array[UInt64]]` |
| `position_double` / `position_doubles`                     | `PositionDef[Double]` / `PositionDef[Array[Double]]` |

### Command Definition

| Function                                                                             | Description                                                 |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| `command(name, description?, options?, positionals?, examples?, subcommands?, run?)` | Define a command or subcommand with an async `run` callback |
| `cli(name, version?, description?, options?, commands?, load_config?)`               | Create a CLI app                                            |

### Context Methods

| Method                                                     | Return                         | Description                                     |
| ---------------------------------------------------------- | ------------------------------ | ----------------------------------------------- |
| `get_bool(OptionDef[Bool])`                                | `Bool`                         | Flag value (default: `false`)                   |
| `get_string(ArgDef[String, M])`                            | `String?`                      | First string value from an option or position   |
| `get_string_required(ArgDef[String, M])`                   | `String raise`                 | Required string value                           |
| `get_int(ArgDef[Int, M])`                                  | `Int?`                         | Parsed integer value from an option or position |
| `get_int_required(ArgDef[Int, M])`                         | `Int raise`                    | Required parsed integer value                   |
| `get_int64` / `get_int64_required`                         | `Int64?` / `Int64 raise`       | 64-bit signed integer value                     |
| `get_uint` / `get_uint_required`                           | `UInt?` / `UInt raise`         | Unsigned integer value                          |
| `get_uint64` / `get_uint64_required`                       | `UInt64?` / `UInt64 raise`     | 64-bit unsigned integer value                   |
| `get_double` / `get_double_required`                       | `Double?` / `Double raise`     | Double-precision floating-point value           |
| `get_strings(ArgDef[Array[String], M])`                    | `Array[String]`                | Repeated string values, empty when unavailable  |
| `get_ints(ArgDef[Array[Int], M])`                          | `Array[Int] raise`             | Repeated parsed integer values                  |
| `get_int64s` / `get_uints` / `get_uint64s` / `get_doubles` | corresponding `Array[T] raise` | Repeated parsed numeric values                  |
| plural getter with `_required` suffix                      | `NonEmptyArray[T] raise`       | Required non-empty repeated values              |
| `get_subcommand()`                                         | `(String, Context)?`           | Selected subcommand name and context            |

### Schema & Completion

| Method                     | Return   | Description                        |
| -------------------------- | -------- | ---------------------------------- |
| `render_schema()`          | `String` | Full CLI definition as JSON string |
| `render_schema_json()`     | `Json`   | Full CLI definition as Json value  |
| `render_bash_completion()` | `String` | Bash completion script             |
| `render_zsh_completion()`  | `String` | Zsh completion script              |
| `render_fish_completion()` | `String` | Fish completion script             |

### Running

```moonbit
app.run()                                    // use process args
app.run(argv=Some(["greet", "--name", "x"])) // explicit args (for testing)
app.run(env={ "ADMIRAL_NAME": "Env" })       // explicit environment map
app.run(
  argv=Some(["greet"]),
  env={ "ADMIRAL_NAME": "Env" },
)
```

`CliApp::run(argv?, env?)` is async. Omitted `argv` uses process arguments, and omitted `env` uses the process environment. Call it from `async fn main` or `async test`; no task-group wrapper is required. `--help` and `--version` are automatically handled by argparse. Invoking the app without a runnable command, or a command group without its required subcommand, displays the corresponding help. Unknown commands, invalid options, and errors raised by command callbacks remain errors.

## Targets

Admiral supports the native target. This follows the current support level of the official `moonbitlang/async` runtime.

## License

MIT. See [LICENSE](LICENSE).

The upstream project declares its original license as MIT in [mizchi/admiral's module manifest](https://github.com/mizchi/admiral/blob/main/moon.mod.json).
