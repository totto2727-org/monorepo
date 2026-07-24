# mdt

A native MoonBit CLI that translates one Markdown file through [OpenCode](https://opencode.ai/docs/server/). It starts an isolated OpenCode server through `totto2727/opencode-sdk`, sends requests with [`DC-Z-lab/moonllm`](https://mooncakes.io/docs/DC-Z-lab/moonllm@0.1.0), reuses the user's existing OpenCode providers and authentication, and denies every tool in the translation session.

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
vp run --filter @totto2727/mdt build
```

The native executable is written to `mbt/app/mdt/dist/mdt`.

## How it works

1. Admiral parses the input path and options into typed command data.
2. The CLI refuses to overwrite an existing output before starting OpenCode unless `--force` is present.
3. `totto2727/opencode-sdk` starts a managed local OpenCode server.
4. The CLI creates a session whose permission rules deny every tool.
5. `moonllm` posts the Markdown and translation instructions to the OpenCode session endpoint.
6. The returned text parts are joined and written to the resolved output path.

The CLI sends the whole file in one prompt. A file larger than the selected model's context window is not chunked.
