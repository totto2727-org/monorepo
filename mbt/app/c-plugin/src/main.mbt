///|
fn target_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="target",
    description="Manage skill symlink target directories",
    subcommands=[target_add_command_def(), target_remove_command_def()],
  )
}

///|
fn skill_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="skill",
    description="Manage skills from plugin repositories",
    subcommands=[
      skill_add_command_def(),
      skill_sync_command_def(),
      skill_update_command_def(),
      skill_remove_command_def(),
      target_command_def(),
    ],
  )
}

///|
fn marketplace_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="marketplace",
    description="Marketplace development tools",
    subcommands=[dev_marketplace_sync_command_def()],
  )
}

///|
fn dev_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="dev",
    description="Development tools for plugin authors",
    subcommands=[marketplace_command_def()],
  )
}

///|
fn parse() -> @argparse.Matches raise {
  @argparse.Command(
    "c-plugin",
    about="CLI to manage Claude Code Plugin resources",
    subcommands=[
      @admiral.build_command(init_command_def()),
      @admiral.build_command(skill_command_def()),
      @admiral.build_command(dev_command_def()),
    ],
  ).parse()
}

///|
async fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("init", command)) => run_init(command)
    Some(("skill", skill)) =>
      match skill.subcommand {
        Some(("add", command)) => run_skill_add(command)
        Some(("sync", command)) => run_skill_sync(command)
        Some(("update", command)) => run_skill_update(command)
        Some(("remove", command)) => run_skill_remove(command)
        Some(("target", target)) =>
          match target.subcommand {
            Some(("add", command)) => run_target_add(command)
            Some(("remove", command)) => run_target_remove(command)
            _ => raise Failure::Failure("missing target subcommand")
          }
        _ => raise Failure::Failure("missing skill subcommand")
      }
    Some(("dev", dev)) =>
      match dev.subcommand {
        Some(("marketplace", market)) =>
          match market.subcommand {
            Some(("sync", command)) => run_dev_marketplace_sync(command)
            _ => raise Failure::Failure("missing marketplace subcommand")
          }
        _ => raise Failure::Failure("missing dev subcommand")
      }
    Some((name, _)) => raise Failure::Failure("unknown command: \{name}")
    None =>
      raise Failure::Failure("no command specified. Use --help for usage.")
  }
}

///|
async fn main {
  dispatch(parse())
}
