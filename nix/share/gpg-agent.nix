{ pkgs }:
{
  enable = true;
  enableSshSupport = true;
  pinentry.package = pkgs.pinentry_mac;
}
