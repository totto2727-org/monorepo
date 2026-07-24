///|
let links_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let links_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let links_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let links_visible_only_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "visible-only",
  description="Only visible links",
  env="BW_VISIBLE_ONLY",
  config="visible_only",
)

///|
let links_internal_only_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "internal-only",
  description="Only same-domain links",
  env="BW_INTERNAL_ONLY",
  config="internal_only",
)

///|
struct LinksOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  visible_only : Bool
  internal_only : Bool
}

///|
struct LinksGotoOptions {
  waitUntil : String
}

///|
struct LinksBody {
  url : String?
  html : String?
  gotoOptions : LinksGotoOptions?
  visibleLinksOnly : Bool?
  excludeExternalLinks : Bool?
}

///|
impl ToJson for LinksGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend LinksGotoOptions with ToJson::{to_json}

///|
impl ToJson for LinksBody with fn to_json(self) -> Json {
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
  put_json_if_some(
    object,
    "visibleLinksOnly",
    match self.visibleLinksOnly {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "excludeExternalLinks",
    match self.excludeExternalLinks {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
extend LinksBody with ToJson::{to_json}

///|
fn links_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="links",
    description="Retrieve links",
    options=[
      account_id_option, api_token_option, links_url_option, links_html_option, links_wait_until_option,
      links_visible_only_option, links_internal_only_option,
    ],
    run=Some(run),
  )
}

///|
async fn links_options(context : @admiral.Context) -> LinksOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(links_url_option),
    html: read_optional_file(context.get_string(links_html_option)),
    wait_until: context.get_string(links_wait_until_option),
    visible_only: context.get_bool(links_visible_only_option),
    internal_only: context.get_bool(links_internal_only_option),
  }
}

///|
fn LinksBody::from_options(options : LinksOptionsInput) -> LinksBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    visibleLinksOnly: if options.visible_only {
      Some(true)
    } else {
      None
    },
    excludeExternalLinks: if options.internal_only {
      Some(true)
    } else {
      None
    },
  }
}

///|
async fn run_links(context : @admiral.Context) -> Unit {
  let options = links_options(context)
  let body = LinksBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/links",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  println(data.text())
}
