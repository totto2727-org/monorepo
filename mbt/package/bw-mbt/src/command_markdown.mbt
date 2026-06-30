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
impl ToJson for MarkdownBody with fn to_json(self) -> Json {
  Json::object({
    "url": match self.url {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "html": match self.html {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "gotoOptions": match self.gotoOptions {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}

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
  ])
}

///|
async fn markdown_options(matches : @argparse.Matches) -> MarkdownOptions {
  {
    account_id: match matches.values.get(markdown_account_id_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_account_id_env) {
          Some(value) => value
          None =>
            fail(
              "account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id",
            )
        }
    },
    api_token: match matches.values.get(markdown_api_token_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_api_token_env) {
          Some(value) => value
          None =>
            fail(
              "api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token",
            )
        }
    },
    url: match matches.values.get(markdown_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(markdown_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(markdown_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    output: match matches.values.get(markdown_output_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
  }
}

///|
fn MarkdownBody::from_options(options : MarkdownOptions) -> MarkdownBody raise {
  guard options.url is Some(_) || options.html is Some(_) else {
    fail("Either --url or --html is required")
  }
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
