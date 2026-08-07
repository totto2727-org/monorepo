///|
fn app(runtime : Runtime) -> @admiral.CliApp {
  @admiral.CliApp::CliApp(
    name="c-plugin",
    version="0.1.0",
    description="Native MoonBit CLI for c-plugin v2",
    commands=[
      init_command_def(async fn(context) { run_init(runtime, context) }),
    ],
  )
}

///|
async fn main {
  let home : @path.Path = @env.get_env_var("HOME").unwrap_or_else(() => {
    fail("HOME is not set")
  })
  let cwd : @path.Path = @env.current_dir().unwrap_or_else(() => {
    fail("failed to resolve current directory")
  })
  let cache_root = home.join(".cache").join("c-plugin").join("repositories")
  let paths = RuntimePaths::RuntimePaths(home, cwd, cache_root)
  let runtime = runtime_for_init(paths)
  app(runtime).run()
}
