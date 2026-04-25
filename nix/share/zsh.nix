{ pkgs }:
{
  enable = true;
  enableCompletion = true;
  plugins = [
    {
      name = "by-binds-yourself";
      file = "by.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "atusy";
        repo = "by-binds-yourself";
        rev = "v1.0.0";
        sha256 = "sha256-x2wwlWH4QAR6NnohIZKm6YarbiZnNPJBDd/r6XqZKP4=";
      };
    }
  ];
}
