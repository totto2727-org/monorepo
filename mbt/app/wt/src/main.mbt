///|
async fn main {
  let app = @admiral.cli(name="wt", description="Git worktree manager", commands=[
    ls_command_def(run_ls),
    cleanup_command_def(run_cleanup),
  ])
  app.run()
}
