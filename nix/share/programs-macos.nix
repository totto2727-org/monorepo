{ pkgs }:
{
  programs = {
    gpg = import ./gpg.nix;
  };
  services = {
    gpg-agent = import ./gpg-agent.nix { inherit pkgs; };
  };
}
