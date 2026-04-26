{
  la = "eza -a --group-directories-first";
  ll = "la -l";
  vi = "nvim";
  vim = "nvim";
  VI = "nvim";
  LG = "lazygit";
  LD = "lazydocker";
  YZ = "yazi";
  P = "podman.lima";
  G = "git";
  GB = "git branch";
  GC = "git commit";
  GCA = "git commit --amend";
  GSW = "git switch";
  GSWC = "git switch -c";
  GPUSHF = "git push --force-with-lease --force-if-includes";
  gh-pr-create = "gh pr create -a '@me' --base";
  path-list = ''
    echo "$PATH" | sd ':' '\n'
  '';
}
