///|
let translate_file_argument : @admiral.PositionDef[String] = @admiral.position_string(
  "file",
  description="Markdown file to translate",
  required=true,
)

///|
let translate_lang_option : @admiral.OptionDef[String] = @admiral.string(
  "lang",
  short='l',
  description="Target language code (for example, ja or ja-JP)",
  required=true,
)

///|
let translate_model_option : @admiral.OptionDef[String] = @admiral.string(
  "model",
  short='m',
  description="Model in provider/model format",
  default=Some("opencode-go/deepseek-v4-flash"),
)

///|
let translate_force_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "force",
  short='f',
  description="Overwrite an existing output file",
)

///|
struct TranslateOptions {
  file : @path.Path
  lang : String
  model : ModelSelection
  force : Bool
}

///|
fn translate_options(context : @admiral.Context) -> TranslateOptions raise {
  {
    file: @path.Path(context.get_string_required(translate_file_argument)),
    lang: normalize_locale(context.get_string_required(translate_lang_option)),
    model: parse_model(context.get_string_required(translate_model_option)),
    force: context.get_bool(translate_force_option),
  }
}

///|
async fn run_translate(context : @admiral.Context) -> Unit {
  let options = translate_options(context)
  let output = target_path(options.file, options.lang)
  let output_text = output.to_string()
  guard options.force || !@fs.exists(output_text) else {
    fail("output file already exists: \{output_text}")
  }
  let input = @fs.read_file(options.file.to_string()).text()
  let translated = translate_markdown(options.lang, options.model, input)
  @fs.write_file(output_text, translated, create_mode=CreateOrTruncate)
  println("Written to \{output_text}")
}
