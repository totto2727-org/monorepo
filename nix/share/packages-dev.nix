{ pkgs }:
with pkgs;
[
  # Coding
  lefthook
  just
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
