///|
fn app() -> @admiral.CliApp {
  @admiral.CliApp::CliApp(
    name="c-plugin",
    version="0.1.0",
    description="Native MoonBit CLI for c-plugin v2",
  )
}

///|
async fn main {
  app().run()
}
