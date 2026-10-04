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
    binName = "@monid-ai/cli";
    packageName = "monid";
  })
  (npm {
    binName = "oo";
    packageName = "@oomol-lab/oo-cli";
  })
]
