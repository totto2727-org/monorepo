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
  # Coding
  nixfmt
  just
  chezmoi
  (npm {
    binName = "monid";
    packageName = "@monid-ai/cli";
  })
  (npm {
    binName = "@oomol-lab/oo-cli";
    packageName = "oo";
  })
]
