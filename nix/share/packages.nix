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
  # npm
  (npm {
    binName = "ctx7";
    packageName = "ctx7";
  })
  (npm {
    binName = "c-plugin";
    packageName = "@totto2727/c-plugin";
  })
  (npm {
    binName = "bw";
    packageName = "@totto2727/bw";
  })
  (npm {
    binName = "wt";
    packageName = "@totto2727/wt";
  })
  # (npm {
  #   binName = "comment-checker";
  #   packageName = "@code-yeongyu/comment-checker";
  #   runtime = "bun";
  #   additionalArgs = "--bun";
  # })
]
