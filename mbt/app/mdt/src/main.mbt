///|
async fn main {
  let app = @admiral.cli(
    name="mdt",
    version="0.1.2",
    description="Translate a Markdown file via OpenCode",
    options=[
      translate_lang_option, translate_model_option, translate_force_option,
    ],
    positionals=[translate_file_argument],
    run=Some(run_translate),
  )
  app.run()
}
