///|
let target_dir_arg : @admiral.PositionDef[String] = @admiral.position_string(
  "dir",
  description="Target directory",
)

///|
fn target_add_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="add",
    description="Add skill symlink target directory",
    positionals=[target_dir_arg],
    options=[global_option],
    run=Some(run),
  )
}

///|
fn target_remove_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="remove",
    description="Remove skill symlink target directory",
    positionals=[target_dir_arg],
    options=[global_option],
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
  let dir = context.get_string_required(target_dir_arg)
  { global: context.get_bool(global_option), dir }
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
  let updated_lock : LockFile = { skill_dirs, repositories: lock.repositories }
  write_lock(agents, updated_lock)
  sync_lock(agents, updated_lock)
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
  let updated_lock : LockFile = { skill_dirs, repositories: lock.repositories }
  write_lock(agents, updated_lock)
  sync_lock(agents, updated_lock)
}
