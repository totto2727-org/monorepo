///|
fn init_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="init",
    description="Create an empty lock file in the current directory",
  )
}

///|
struct InitOptions {
  global : Bool
}

///|
fn init_options(_matches : @argparse.Matches) -> InitOptions {
  { global: false }
}

///|
async fn run_init(matches : @argparse.Matches) -> Unit {
  let options = init_options(matches)
  let agents = agents_dir(options.global)
  if !@fs.exists(agents) {
    @fs.mkdir(agents, recursive=true)
  }
  let path = lock_path_from_agents(agents)
  guard !@fs.exists(path) else { fail("lock file already exists: \{path}") }
  @fs.write_file(path, empty_lock_text(), create_mode=CreateOrTruncate)
  println("Created \{path}")
}
