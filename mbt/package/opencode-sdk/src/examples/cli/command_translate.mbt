///|
let translate_text_argument : @admiral.PositionDef[String] = @admiral.position_string(
  "text",
  description="Text to translate into English",
  required=true,
)

///|
struct TranslateOptions {
  text : String
}

///|
fn translate_options(context : @admiral.Context) -> TranslateOptions raise {
  { text: context.get_string_required(translate_text_argument) }
}

///|
fn translate_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="translate",
    description="Translate text into English without tools",
    positionals=[translate_text_argument],
    examples=["opencode-example translate 'MoonBitでSDKを実装しています。'"],
    run=Some(run),
  )
}

///|
async fn run_translate(context : @admiral.Context) -> Unit {
  let options = translate_options(context)
  let output = run_prompt({
    title: "English translation",
    tool_access: NoTools,
    system:
      "You are a professional translator. Translate the user's text into natural English. Preserve its meaning, tone, names, and formatting. Return only the English translation with no commentary.",
    text: options.text,
  })
  println(output)
}
