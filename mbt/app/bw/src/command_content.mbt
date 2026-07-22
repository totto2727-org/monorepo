///|
let content_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
)

///|
let content_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
)

///|
let content_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
)

///|
let content_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
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
impl ToJson for ContentGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend ContentGotoOptions with ToJson::{to_json}

///|
impl ToJson for ContentBody with fn to_json(self) -> Json {
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
extend ContentBody with ToJson::{to_json}

///|
fn content_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="content",
    description="Fetch rendered HTML",
    options=[
      account_id_option, api_token_option, content_url_option, content_html_option,
      content_wait_until_option, content_output_option, config_option,
    ],
    run=Some(run),
  )
}

///|
async fn content_options(context : @admiral.Context) -> ContentOptions {
  let config = load_config(context)
  {
    account_id: merged_account_id(context, config),
    api_token: merged_api_token(context, config),
    url: merge_string(cli_string(context, content_url_option), config.url),
    html: merged_html(context, content_html_option, config),
    wait_until: merge_string(
      cli_string(context, content_wait_until_option),
      config.wait_until,
    ),
    output: merge_string(
      cli_string(context, content_output_option),
      config.output,
    ),
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
