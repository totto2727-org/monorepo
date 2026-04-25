{
  enable = true;
  enableZshIntegration = true;
  settings = {
    git = {
      pagers = [
        {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        }
      ];
    };
  };
}
