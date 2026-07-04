///|
let scrape_account_id_option = "account-id"

///|
let scrape_api_token_option = "api-token"

///|
let scrape_url_option = "url"

///|
let scrape_html_option = "html"

///|
let scrape_wait_until_option = "wait-until"

///|
let scrape_selector_option = "selector"

///|
struct ScrapeOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  selector : String
}

///|
struct ScrapeGotoOptions {
  waitUntil : String
}

///|
struct ScrapeElement {
  selector : String
}

///|
struct ScrapeBody {
  url : String?
  html : String?
  gotoOptions : ScrapeGotoOptions?
  elements : Array[ScrapeElement]
}

///|
impl ToJson for ScrapeGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for ScrapeElement with fn to_json(self) -> Json {
  Json::object({ "selector": self.selector.to_json() })
}

///|
impl ToJson for ScrapeBody with fn to_json(self) -> Json {
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
  object.set("elements", self.elements.to_json())
  Json::object(object)
}

///|
fn scrape_command_def() -> @admiral.CommandDef {
  @admiral.command(name="scrape", description="Extract elements", options=[
    @admiral.string(
      scrape_account_id_option,
      description="Cloudflare account ID",
    ),
    @admiral.string(scrape_api_token_option, description="Cloudflare API token"),
    @admiral.string(scrape_url_option, description="Target URL"),
    @admiral.string(scrape_html_option, description="Path to local HTML file"),
    @admiral.string(scrape_wait_until_option, description="Page load strategy"),
    @admiral.string(
      scrape_selector_option,
      description="CSS selector",
      required=true,
    ),
  ])
}

///|
async fn scrape_options(matches : @argparse.Matches) -> ScrapeOptionsInput {
  {
    account_id: match matches.values.get(scrape_account_id_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_account_id_env) {
          Some(value) => value
          None =>
            raise Failure::Failure(
              "account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id",
            )
        }
    },
    api_token: match matches.values.get(scrape_api_token_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_api_token_env) {
          Some(value) => value
          None =>
            raise Failure::Failure(
              "api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token",
            )
        }
    },
    url: match matches.values.get(scrape_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(scrape_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(scrape_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    selector: {
      let values = matches.values
        .get(scrape_selector_option)
        .unwrap_or_error(Failure::Failure("missing required option: selector"))
      match values {
        [value, ..] => value
        [] => raise Failure::Failure("missing required option: selector")
      }
    },
  }
}

///|
fn ScrapeBody::from_options(options : ScrapeOptionsInput) -> ScrapeBody raise {
  guard options.url is Some(_) || options.html is Some(_) else {
    raise Failure::Failure("Either --url or --html is required")
  }
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    elements: [{ selector: options.selector }],
  }
}

///|
async fn run_scrape(matches : @argparse.Matches) -> Unit {
  let options = scrape_options(matches)
  let body = ScrapeBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/scrape",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  println(data.text())
}
