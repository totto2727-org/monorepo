{
  username,
  homedir,
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  users.users.${username}.home = homedir;
}
