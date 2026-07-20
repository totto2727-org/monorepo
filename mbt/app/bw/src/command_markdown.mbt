///|
let markdown_account_id_option = "account-id"

///|
let markdown_api_token_option = "api-token"

///|
let markdown_url_option = "url"

///|
let markdown_html_option = "html"

///|
let markdown_wait_until_option = "wait-until"

///|
let markdown_output_option = "output"

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
fn markdown_command_def() -> @admiral.CommandDef {
  @admiral.command(name="markdown", description="Extract markdown", options=[
    @admiral.string(
      markdown_account_id_option,
      description="Cloudflare account ID",
    ),
    @admiral.string(
      markdown_api_token_option,
      description="Cloudflare API token",
    ),
    @admiral.string(markdown_url_option, description="Target URL"),
    @admiral.string(markdown_html_option, description="Path to local HTML file"),
    @admiral.string(
      markdown_wait_until_option,
      description="Page load strategy",
    ),
    @admiral.string(
      markdown_output_option,
      short='o',
      description="Output file path",
    ),
    @admiral.string(config_option, description="Path to JSON config file"),
  ])
}

///|
async fn markdown_options(matches : @argparse.Matches) -> MarkdownOptions {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, markdown_url_option), config.url),
    html: merged_html(matches, markdown_html_option, config),
    wait_until: merge_string(
      cli_string(matches, markdown_wait_until_option),
      config.wait_until,
    ),
    output: merge_string(
      cli_string(matches, markdown_output_option),
      config.output,
    ),
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
async fn run_markdown_command(matches : @argparse.Matches) -> Unit {
  let options = markdown_options(matches)
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
