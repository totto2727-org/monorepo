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
    binName = "srt";
    packageName = "@anthropic-ai/sandbox-runtime";
  })
  (npm {
    binName = "skills";
    packageName = "skills";
  })
  (npm {
    binName = "pi";
    packageName = "@mariozechner/pi-coding-agent";
  })
  (npm {
    binName = "ctx7";
    packageName = "ctx7";
  })
]
