///|
let init_global_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "global",
  short='g',
  description="Create the user-level lock file",
)

///|
struct InitOptions {
  global : Bool
}

///|
fn init_options(
  context : @admiral.Context,
) -> InitOptions raise @json.JsonDecodeError {
  { global: context.get_bool(init_global_option) }
}

///|
fn runtime_for_init(paths : RuntimePaths) -> Runtime {
  Runtime::Runtime(
    paths~,
    discover_locks_api=discover_locks,
    load_lock~,
    create_lock_exclusive~,
    write_lock_atomic~,
    load_ownership_state~,
    write_ownership_state_atomic~,
  )
}

///|
/// Create an empty project or global v2 lock without replacing existing bytes.
async fn init_lock(runtime : Runtime, options : InitOptions) -> @path.Path {
  let lock_path = if options.global {
    runtime.global_lock_path()
  } else {
    runtime.project_lock_path()
  }
  runtime.create_lock_exclusive(lock_path, Lock::Lock([], []))
  lock_path
}

///|
async fn run_init(runtime : Runtime, context : @admiral.Context) -> Unit {
  let lock_path = init_lock(runtime, init_options(context))
  println("Created " + lock_path.to_string())
}

///|
fn init_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.CommandDef::CommandDef(
    name="init",
    description="Create an empty c-plugin lock file",
    options=[init_global_option],
    run=Some(run),
  )
}
