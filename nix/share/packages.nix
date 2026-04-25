{ pkgs, npm }:
with pkgs;
[
  git
  # CLI
  eza
  ripgrep
  sd
  fd
  rename
  fzf
  starship
  # TUI
  lazygit
  lazydocker
  yazi
  # Coding
  devbox
  chezmoi
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
  # npm
  (npm {
    name = "srt";
    packageName = "@anthropic-ai/sandbox-runtime";
    additionalArgs = "";
  })
  (npm {
    name = "skills";
    packageName = "skills";
  })
  (npm {
    name = "pi";
    packageName = "@mariozechner/pi-coding-agent";
  })
  (npm {
    name = "ctx7";
    packageName = "ctx7";
  })
]
