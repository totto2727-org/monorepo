{ pkgs, npm }:
with pkgs;
[
  git
  # CLI
  witr
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
  (npm {
    binName = "monid";
    packageName = "@monid-ai/cli";
  })
  (npm {
    binName = "oo";
    packageName = "@oomol-lab/oo-cli";
  })
]
