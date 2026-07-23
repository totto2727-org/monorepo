///|
let markdown_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env=url_env,
  config="url",
)

///|
let markdown_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env=html_env,
  config="html",
)

///|
let markdown_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env=wait_until_env,
  config="wait_until",
)

///|
let markdown_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env=output_env,
  config="output",
)

///|
struct MarkdownOptions {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String?
}

///|
struct MarkdownGotoOptions {
  waitUntil : String
}

///|
struct MarkdownBody {
  url : String?
  html : String?
  gotoOptions : MarkdownGotoOptions?
}

///|
impl ToJson for MarkdownGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend MarkdownGotoOptions with ToJson::{to_json}

///|
impl ToJson for MarkdownBody with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  put_json_if_some(
    object,
    "url",
    match self.url {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "html",
    match self.html {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "gotoOptions",
    match self.gotoOptions {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
extend MarkdownBody with ToJson::{to_json}

///|
fn markdown_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="markdown",
    description="Extract markdown",
    options=[
      account_id_option, api_token_option, markdown_url_option, markdown_html_option,
      markdown_wait_until_option, markdown_output_option,
    ],
    run=Some(run),
  )
}

///|
async fn markdown_options(context : @admiral.Context) -> MarkdownOptions {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(markdown_url_option),
    html: read_optional_file(context.get_string(markdown_html_option)),
    wait_until: context.get_string(markdown_wait_until_option),
    output: context.get_string(markdown_output_option),
  }
}

///|
fn MarkdownBody::from_options(options : MarkdownOptions) -> MarkdownBody raise {
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
async fn run_markdown_command(context : @admiral.Context) -> Unit {
  let options = markdown_options(context)
  let body = MarkdownBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/markdown",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_text_or_stdout(options.output, data.text())
}
