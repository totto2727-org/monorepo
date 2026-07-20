///|
let content_account_id_option = "account-id"

///|
let content_api_token_option = "api-token"

///|
let content_url_option = "url"

///|
let content_html_option = "html"

///|
let content_wait_until_option = "wait-until"

///|
let content_output_option = "output"

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
      @admiral.string(
        content_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(
        content_api_token_option,
        description="Cloudflare API token",
      ),
      @admiral.string(content_url_option, description="Target URL"),
      @admiral.string(
        content_html_option,
        description="Path to local HTML file",
      ),
      @admiral.string(
        content_wait_until_option,
        description="Page load strategy",
      ),
      @admiral.string(
        content_output_option,
        short='o',
        description="Output file path",
      ),
      @admiral.string(config_option, description="Path to JSON config file"),
    ],
    run=Some(run),
  )
}

///|
async fn content_options(matches : @admiral.Context) -> ContentOptions {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, content_url_option), config.url),
    html: merged_html(matches, content_html_option, config),
    wait_until: merge_string(
      cli_string(matches, content_wait_until_option),
      config.wait_until,
    ),
    output: merge_string(
      cli_string(matches, content_output_option),
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
async fn run_content_command(matches : @admiral.Context) -> Unit {
  let options = content_options(matches)
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
