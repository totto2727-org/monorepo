///|
let content_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let content_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let content_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let content_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env="BW_OUTPUT",
  config="output",
)

///|
struct ContentOptions {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String?
}

///|
struct ContentGotoOptions {
  waitUntil : String
}

///|
struct ContentBody {
  url : String?
  html : String?
  gotoOptions : ContentGotoOptions?
}

///|
let content_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let content_body_url_lens : @lens.PresenceLens[String] = @lens.root()
  .string("url")
  .optional()

///|
let content_body_html_lens : @lens.PresenceLens[String] = @lens.root()
  .string("html")
  .optional()

///|
let content_body_goto_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
impl ToJson for ContentGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  content_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend ContentGotoOptions with ToJson::{to_json}

///|
impl ToJson for ContentBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  content_body_url_lens.set_or_abort(builder, self.url)
  content_body_html_lens.set_or_abort(builder, self.html)
  content_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  builder.to_json()
}

///|
extend ContentBody with ToJson::{to_json}

///|
fn content_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.CommandDef::CommandDef(
    name="content",
    description="Fetch rendered HTML",
    options=[
      account_id_option, api_token_option, content_url_option, content_html_option,
      content_wait_until_option, content_output_option,
    ],
    run=Some(run),
  )
}

///|
async fn content_options(context : @admiral.Context) -> ContentOptions {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(content_url_option),
    html: read_optional_file(context.get_string(content_html_option)),
    wait_until: context.get_string(content_wait_until_option),
    output: context.get_string(content_output_option),
  }
}

///|
fn ContentBody::from_options(options : ContentOptions) -> ContentBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
  }
}

///|
async fn run_content_command(context : @admiral.Context) -> Unit {
  let options = content_options(context)
  let body = ContentBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/content",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_text_or_stdout(options.output, data.text())
}
