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
  devbox
  chezmoi
  # npm
  (npm {
    binName = "ctx7";
    packageName = "ctx7";
  })
  (npm {
    binName = "wt";
    packageName = "@totto2727/wt";
  })
  (npm {
    binName = "mdt";
    packageName = "@totto2727/mdt";
  })
  (npm {
    binName = "openshell";
    runtime = "uv";
    packageName = "openshell";
  })
]
