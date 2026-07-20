///|
let target_dir_arg = "dir"

///|
fn target_add_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
  @admiral.command(
    name="add",
    description="Add skill symlink target directory",
    positionals=[
      @admiral.positional(target_dir_arg, description="Target directory"),
    ],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
    run=Some(run),
  )
}

///|
fn target_remove_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
  @admiral.command(
    name="remove",
    description="Remove skill symlink target directory",
    positionals=[
      @admiral.positional(target_dir_arg, description="Target directory"),
    ],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
    run=Some(run),
  )
}

///|
struct TargetOptions {
  global : Bool
  dir : String
}

///|
fn target_options(context : @admiral.Context) -> TargetOptions raise {
  let values = match context.values.get(target_dir_arg) {
    Some(values) => values
    None => fail("dir is required")
  }
  let dir = match values {
    [value, ..] => value
    [] => fail("dir is required")
  }
  { global: context.flags.contains(global_option), dir }
}

///|
async fn run_target_add(context : @admiral.Context) -> Unit {
  let options = target_options(context)
  let agents = command_agents_dir(options.global)
  let dir = options.dir
  let lock = read_lock(agents)
  let skill_dirs = if lock.skill_dirs.contains(dir) {
    lock.skill_dirs
  } else {
    lock.skill_dirs.iter().concat([dir].iter()).collect()
  }
  write_lock(agents, { skill_dirs, repositories: lock.repositories })
  sync_all(agents)
}

///|
async fn run_target_remove(context : @admiral.Context) -> Unit {
  let options = target_options(context)
  let agents = command_agents_dir(options.global)
  let dir = options.dir
  let lock = read_lock(agents)
  let skill_dirs = lock.skill_dirs
    .iter()
    .filter(fn(item) { item != dir })
    .collect()
  write_lock(agents, { skill_dirs, repositories: lock.repositories })
  sync_all(agents)
}
