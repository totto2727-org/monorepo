///|
let scrape_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let scrape_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let scrape_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let scrape_selector_option : @admiral.OptionDef[String] = @admiral.string(
  "selector",
  description="CSS selector",
  env="BW_SELECTOR",
  config="selector",
  required=true,
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
let scrape_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let scrape_element_selector_lens : @lens.Lens[String] = @lens.root().string(
  "selector",
)

///|
let scrape_body_url_lens : @lens.PresenceLens[String] = @lens.root()
  .string("url")
  .optional()

///|
let scrape_body_html_lens : @lens.PresenceLens[String] = @lens.root()
  .string("html")
  .optional()

///|
let scrape_body_goto_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
let scrape_body_elements_lens : @lens.Lens[Json] = @lens.root().json("elements")

///|
impl ToJson for ScrapeGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  scrape_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend ScrapeGotoOptions with ToJson::{to_json}

///|
impl ToJson for ScrapeElement with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  scrape_element_selector_lens.set_or_abort(builder, self.selector)
  builder.to_json()
}

///|
impl ToJson for ScrapeBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  scrape_body_url_lens.set_or_abort(builder, self.url)
  scrape_body_html_lens.set_or_abort(builder, self.html)
  scrape_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  scrape_body_elements_lens.set_or_abort(builder, self.elements.to_json())
  builder.to_json()
}

///|
extend ScrapeBody with ToJson::{to_json}

///|
fn scrape_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.CommandDef::CommandDef(
    name="scrape",
    description="Extract elements",
    options=[
      account_id_option, api_token_option, scrape_url_option, scrape_html_option,
      scrape_wait_until_option, scrape_selector_option,
    ],
    run=Some(run),
  )
}

///|
async fn scrape_options(context : @admiral.Context) -> ScrapeOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(scrape_url_option),
    html: read_optional_file(context.get_string(scrape_html_option)),
    wait_until: context.get_string(scrape_wait_until_option),
    selector: context.get_string_required(scrape_selector_option),
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
