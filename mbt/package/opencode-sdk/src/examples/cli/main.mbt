///|
async fn main {
  let app = @admiral.cli(
    name="opencode-example",
    description="OpenCode server management SDK examples",
    commands=[
      translate_command_def(run_translate),
      summarize_url_command_def(run_summarize_url),
    ],
  )
  app.run()
}
