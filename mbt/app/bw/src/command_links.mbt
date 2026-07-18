///|
let links_account_id_option = "account-id"

///|
let links_api_token_option = "api-token"

///|
let links_url_option = "url"

///|
let links_html_option = "html"

///|
let links_wait_until_option = "wait-until"

///|
let links_visible_only_option = "visible-only"

///|
let links_internal_only_option = "internal-only"

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
fn links_command_def() -> @admiral.CommandDef {
  @admiral.command(name="links", description="Retrieve links", options=[
    @admiral.string(
      links_account_id_option,
      description="Cloudflare account ID",
    ),
    @admiral.string(links_api_token_option, description="Cloudflare API token"),
    @admiral.string(links_url_option, description="Target URL"),
    @admiral.string(links_html_option, description="Path to local HTML file"),
    @admiral.string(links_wait_until_option, description="Page load strategy"),
    @admiral.bool(links_visible_only_option, description="Only visible links"),
    @admiral.bool(
      links_internal_only_option,
      description="Only same-domain links",
    ),
    @admiral.string(config_option, description="Path to JSON config file"),
  ])
}

///|
async fn links_options(matches : @argparse.Matches) -> LinksOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, links_url_option), config.url),
    html: merged_html(matches, links_html_option, config),
    wait_until: merge_string(
      cli_string(matches, links_wait_until_option),
      config.wait_until,
    ),
    visible_only: merge_bool(
      matches.flags.get(links_visible_only_option).unwrap_or(false),
      config.visible_only,
      false,
    ),
    internal_only: merge_bool(
      matches.flags.get(links_internal_only_option).unwrap_or(false),
      config.internal_only,
      false,
    ),
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
async fn run_links(matches : @argparse.Matches) -> Unit {
  let options = links_options(matches)
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
