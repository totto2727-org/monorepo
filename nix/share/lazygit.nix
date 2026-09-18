{
  enable = true;
  enableZshIntegration = true;
  settings = {
    git = {
      diffRenderers = [
        {
          colorArg = "always";
          command = "delta --dark --paging=never";
        }
      ];
    };
  };
}
