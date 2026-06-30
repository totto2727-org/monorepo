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
impl ToJson for ContentBody with fn to_json(self) -> Json {
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
fn content_command_def() -> @admiral.CommandDef {
  @admiral.command(name="content", description="Fetch rendered HTML", options=[
    @admiral.string(
      content_account_id_option,
      description="Cloudflare account ID",
    ),
    @admiral.string(
      content_api_token_option,
      description="Cloudflare API token",
    ),
    @admiral.string(content_url_option, description="Target URL"),
    @admiral.string(content_html_option, description="Path to local HTML file"),
    @admiral.string(content_wait_until_option, description="Page load strategy"),
    @admiral.string(
      content_output_option,
      short='o',
      description="Output file path",
    ),
  ])
}

///|
async fn content_options(matches : @argparse.Matches) -> ContentOptions {
  {
    account_id: match matches.values.get(content_account_id_option) {
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
    api_token: match matches.values.get(content_api_token_option) {
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
    url: match matches.values.get(content_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(content_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(content_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    output: match matches.values.get(content_output_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
  }
}

///|
fn ContentBody::from_options(options : ContentOptions) -> ContentBody raise {
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
async fn run_content_command(matches : @argparse.Matches) -> Unit {
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
