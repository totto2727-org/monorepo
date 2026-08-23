{ pkgs }:
{
  direnv = import ./direnv.nix;
  zoxide = import ./zoxide.nix;
  git = import ./git.nix;
  gh = import ./gh.nix { inherit pkgs; };
  delta = import ./delta.nix;
  lazygit = import ./lazygit.nix;
}
