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
    "visibleLinksOnly": match self.visibleLinksOnly {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "excludeExternalLinks": match self.excludeExternalLinks {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
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
  ])
}

///|
async fn links_options(matches : @argparse.Matches) -> LinksOptionsInput {
  {
    account_id: match matches.values.get(links_account_id_option) {
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
    api_token: match matches.values.get(links_api_token_option) {
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
    url: match matches.values.get(links_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(links_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(links_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    visible_only: matches.flags.get(links_visible_only_option).unwrap_or(false),
    internal_only: matches.flags
    .get(links_internal_only_option)
    .unwrap_or(false),
  }
}

///|
fn LinksBody::from_options(options : LinksOptionsInput) -> LinksBody raise {
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
