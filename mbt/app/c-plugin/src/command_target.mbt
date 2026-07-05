///|
let target_dir_arg = "dir"

///|
fn target_add_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="add",
    description="Add skill symlink target directory",
    positionals=[
      @admiral.positional(target_dir_arg, description="Target directory"),
    ],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
  )
}

///|
fn target_remove_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="remove",
    description="Remove skill symlink target directory",
    positionals=[
      @admiral.positional(target_dir_arg, description="Target directory"),
    ],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
  )
}

///|
struct TargetOptions {
  global : Bool
  dir : String
}

///|
fn target_options(matches : @argparse.Matches) -> TargetOptions raise {
  let values = matches.values
    .get(target_dir_arg)
    .unwrap_or_error(Failure::Failure("dir is required"))
  let dir = match values {
    [value, ..] => value
    [] => raise Failure::Failure("dir is required")
  }
  { global: matches.flags.contains(global_option), dir }
}

///|
async fn run_target_add(matches : @argparse.Matches) -> Unit {
  let options = target_options(matches)
  let agents = command_agents_dir(options.global)
  let dir = options.dir
  let lock = read_lock(agents)
  if !lock.skill_dirs.contains(dir) {
    lock.skill_dirs.push(dir)
  }
  write_lock(agents, lock)
  sync_all(agents)
}

///|
async fn run_target_remove(matches : @argparse.Matches) -> Unit {
  let options = target_options(matches)
  let agents = command_agents_dir(options.global)
  let dir = options.dir
  let lock = read_lock(agents)
  let kept : Array[String] = []
  for item in lock.skill_dirs {
    if item != dir {
      kept.push(item)
    }
  }
  write_lock(agents, { skill_dirs: kept, repositories: lock.repositories })
  sync_all(agents)
}
