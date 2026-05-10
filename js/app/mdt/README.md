# mdt

A CLI that translates a single markdown file using the [opencode SDK](https://opencode.ai/docs/sdk/) as its engine. It reuses your existing opencode authentication and provider configuration, and locks down every available tool so the model can only read the input prompt and produce text output.

## Why this exists

- You already have opencode set up with providers and auth — `mdt` borrows that wiring instead of asking for new API keys.
- Translation is a single-shot text task; the agent harness, filesystem access, and shell tools that opencode normally exposes are unnecessary and risky for this use case.
- `mdt` runs an in-process opencode server, fetches every tool ID via `/experimental/tool/ids`, and disables them all on the prompt. The model sees the input markdown and nothing else.

## Install

This package is part of the workspace; install once at the repo root:

```bash
pnpm install
vp run --filter @totto2727/mdt build
```

The binary lands at `js/app/mdt/dist/bin.mjs`.

## Usage

```bash
mdt <file> --lang <code> [--model <provider/model>] [--force]
```

| Flag      | Alias | Description                                    | Default                         |
| --------- | ----- | ---------------------------------------------- | ------------------------------- |
| `--lang`  | `-l`  | Target language code (e.g. `ja`, `en`)         | required                        |
| `--model` | `-m`  | Model in `provider/model` format               | `opencode-go/deepseek-v4-flash` |
| `--force` | `-f`  | Overwrite the output file if it already exists | off                             |

### Output path rules

`mdt` writes to a sibling file with the language tag inserted before the extension. Compound extensions like `.mbt.md` are preserved.

| Input             | `--lang ja` output                               |
| ----------------- | ------------------------------------------------ |
| `hoge.md`         | `hoge.ja.md`                                     |
| `hoge.mbt.md`     | `hoge.ja.mbt.md`                                 |
| `README.draft.md` | `README.draft.ja.md`                             |
| `hoge.en.md`      | `hoge.ja.md` (existing language tag is replaced) |
| `hoge.en.mbt.md`  | `hoge.ja.mbt.md`                                 |

The known language tags are `ja` and `en`. The known compound extensions are `.mbt.md`. Both lists live in `src/lib/path.ts`.

## Examples

```bash
# Translate to Japanese with the default model
mdt docs/intro.md --lang ja

# Translate to English with a specific model
mdt docs/intro.ja.md --lang en --model anthropic/claude-sonnet-4-6

# Overwrite an existing translation
mdt docs/intro.md --lang ja --force
```

## Editor integration

Any editor that can run a shell command on the current buffer can drive `mdt`. The Zed example below assumes the binary is on `PATH`.

`.zed/tasks.json`:

```json
[
  {
    "label": "mdt: translate to ja",
    "command": "mdt $ZED_FILE --lang ja"
  }
]
```

## How it works

1. `createOpencode()` boots an in-process opencode server that inherits your `opencode.json` and stored credentials.
2. `client.tool.ids()` enumerates every built-in and MCP-registered tool.
3. `client.session.create()` opens a fresh session.
4. `client.session.prompt()` sends the file contents with `tools` set to `{ [id]: false }` for every ID, plus a system prompt that constrains the model to emit only the translated markdown.
5. `client.session.messages()` retrieves the assistant response, and the concatenated text parts are written to the resolved output path.
6. The opencode server is closed when the Effect scope exits.

## Limitations

- The default model `opencode-go/deepseek-v4-flash` must be configured as a provider in your opencode setup. Override with `--model` if you use a different provider.
- The `/experimental/tool/ids` endpoint is currently under `experimental` in the opencode API. The SDK should track any future relocation, but breakage is possible.
- Large markdown files may exceed the model's context window. There is no chunking; one prompt translates the whole file.
