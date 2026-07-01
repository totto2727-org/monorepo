///|
fn init_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="init",
    description="Create an empty lock file in the current directory",
  )
}

///|
async fn run_init(_matches : @argparse.Matches) -> Unit {
  let agents = agents_dir(false)
  if !@fs.exists(agents) {
    @fs.mkdir(agents, recursive=true)
  }
  let path = lock_path_from_agents(agents)
  guard !@fs.exists(path) else { fail("lock file already exists: \{path}") }
  @fs.write_file(path, empty_lock_text(), create_mode=CreateOrTruncate)
  println("Created \{path}")
}
