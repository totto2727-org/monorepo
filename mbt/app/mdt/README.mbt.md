# mdt

A native MoonBit CLI that translates one Markdown file through [`opencode run --format json`](https://dev.opencode.ai/docs/cli/). It uses `totto2727/opencode-sdk` to run the installed OpenCode CLI, reuses the user's existing providers and authentication, and denies every tool through `OPENCODE_CONFIG_CONTENT`.

## Usage

```bash
mdt <file> --lang <code> [--model <provider/model>] [--force]
```

| Flag      | Alias | Description                                   | Default                         |
| --------- | ----- | --------------------------------------------- | ------------------------------- |
| `--lang`  | `-l`  | Target language code, such as `ja` or `ja-JP` | required                        |
| `--model` | `-m`  | Model in `provider/model` format              | `opencode-go/deepseek-v4-flash` |
| `--force` | `-f`  | Overwrite an existing output file             | off                             |

The output is written beside the input with the normalized language tag before its extension. Existing language tags are replaced, and compound `.mbt.md` extensions are preserved.

```text
README.md         -> README.ja.md
guide.en.md       -> guide.ja.md
module.mbt.md     -> module.ja.mbt.md
module.en.mbt.md  -> module.ja.mbt.md
```

## Build

Run from the repository root:

```bash
vp run mbt:build
```

The native executable is written under the repository-root `_build/` tree.

## How it works

1. Admiral parses the input path and options into typed command data.
2. The CLI refuses to overwrite an existing output before starting OpenCode unless `--force` is present.
3. `totto2727/opencode-sdk` starts `opencode run --format json` with the selected model.
4. The SDK sends a deny-all OpenCode permission configuration through `OPENCODE_CONFIG_CONTENT`.
5. The translation instructions and Markdown are written to the OpenCode process through stdin.
6. Typed JSONL text events are joined and written to the resolved output path.

The CLI sends the whole file in one prompt. A file larger than the selected model's context window is not chunked.
