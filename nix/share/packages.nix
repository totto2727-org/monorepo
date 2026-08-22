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
  neovim
  lazygit
  lazydocker
  yazi
  # Coding
  codex
  chezmoi
  # MoonBit
  (npm {
    binName = "wt";
    runtime = "moon";
    packageName = "totto2727/wt";
  })
  # npm
  (npm {
    binName = "ctx7";
    packageName = "ctx7";
  })
  (npm {
    binName = "openshell";
    runtime = "uv";
    packageName = "openshell";
  })
]
