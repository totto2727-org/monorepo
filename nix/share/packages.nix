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
  # TUI
  neovim
  lazygit
  yazi
  # Coding
  nixfmt
  just
  chezmoi
]
++ lib.optionals (pkgs ? witr) [ pkgs.witr ]
