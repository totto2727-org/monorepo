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
  bottom
  witr
  # TUI
  neovim
  lazygit
  yazi
  jcode
  # Coding
  nixfmt
  just
  chezmoi
  # uv
  (npm {
    binName = "openshell";
    runtime = "uv";
    packageName = "openshell";
  })
]
