///|
fn command_defs() -> Array[@admiral.CommandDef] {
  [ls_command_def(), cleanup_command_def()]
}

///|
fn parse() -> @argparse.Matches raise {
  @argparse.Command(
    "wt",
    about="Git worktree manager",
    subcommands=command_defs().map(fn(cmd) { @admiral.build_command(cmd) }),
  ).parse()
}

///|
async fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("ls", command)) => run_ls(command)
    Some(("cleanup", command)) => run_cleanup(command)
    Some((name, _)) => raise Failure::Failure("unknown command: \{name}")
    None =>
      raise Failure::Failure("no command specified. Use --help for usage.")
  }
}

///|
async fn main {
  dispatch(parse())
}
