{ pkgs }:
with pkgs;
[
  # Coding
  lefthook
  go-task
  nixfmt-rfc-style
  duckdb
  # Runtime
  nodejs
  bun
  deno
  pnpm
  typescript
  typescript-language-server
  python3
  pyright
  uv
  go
  rustup
]
