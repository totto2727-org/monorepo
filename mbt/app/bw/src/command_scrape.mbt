///|
let scrape_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
)

///|
let scrape_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
)

///|
let scrape_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
)

///|
let scrape_selector_option : @admiral.OptionDef[String] = @admiral.string(
  "selector",
  description="CSS selector",
)

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
extend ScrapeGotoOptions with ToJson::{to_json}

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
extend ScrapeBody with ToJson::{to_json}

///|
fn scrape_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="scrape",
    description="Extract elements",
    options=[
      account_id_option, api_token_option, scrape_url_option, scrape_html_option,
      scrape_wait_until_option, scrape_selector_option, config_option,
    ],
    run=Some(run),
  )
}

///|
async fn scrape_options(context : @admiral.Context) -> ScrapeOptionsInput {
  let config = load_config(context)
  {
    account_id: merged_account_id(context, config),
    api_token: merged_api_token(context, config),
    url: merge_string(cli_string(context, scrape_url_option), config.url),
    html: merged_html(context, scrape_html_option, config),
    wait_until: merge_string(
      cli_string(context, scrape_wait_until_option),
      config.wait_until,
    ),
    selector: required_value(
      "selector",
      merge_string(cli_string(context, scrape_selector_option), config.selector),
    ),
  }
}

///|
fn ScrapeBody::from_options(options : ScrapeOptionsInput) -> ScrapeBody raise {
  required_body_source(options.url, options.html)
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
async fn run_scrape(context : @admiral.Context) -> Unit {
  let options = scrape_options(context)
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
