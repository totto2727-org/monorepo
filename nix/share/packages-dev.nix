{ pkgs }:
with pkgs;
[
  # Coding
  just
  nixfmt
  duckdb
  # Runtime
  nodejs_24
  bun
  deno
  vite-plus
  python3
  uv
  go
  rustup
  moonbit-bin.moonbit.latest
]
