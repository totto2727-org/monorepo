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
  # TUI
  neovim
  zmx
  lazygit
  lazydocker
  yazi
  witr
  # Coding
  codex
  chezmoi
  # uv
  (npm {
    binName = "openshell";
    runtime = "uv";
    packageName = "openshell";
  })
]
