{
  enable = true;
  ignores = [
    "**/.totto/"
    "**/.DS_Store"
    "**/*.local*"
    "!**/*.local.template*"
  ];
  settings = {
    commit = {
      gpgSign = true;
    };
    pull = {
      rebase = true;
      autostash = true;
    };
    core = {
      ignorecase = false;
    };
    init = {
      defaultBranch = "main";
    };
    merge = {
      conflictstyle = "zdiff3";
    };
    alias = {
      unstage = "reset --mixed";
      undo = "reset --mixed HEAD^";
    };
    merge = {
      tool = "vimdiff";
      algorithm = "histogram";
    };
  };
  includes = [
    {
      path = "~/.gitconfig";
    }
  ];
}
