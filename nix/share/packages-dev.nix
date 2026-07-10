{ pkgs }:
with pkgs;
[
  # Coding
  lefthook
  just
  nixfmt
  duckdb
  # Runtime
  nodejs
  bun
  deno
  typescript
  typescript-language-server
  python3
  pyright
  uv
  go
  rustup
  beamPackages.erlang
]
