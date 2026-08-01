{ pkgs }:
{
  enable = true;
  extensions = [
    pkgs.gh-poi
    pkgs.gh-stack
  ];
  gitCredentialHelper.enable = true;
}
