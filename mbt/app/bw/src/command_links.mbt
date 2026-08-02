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
let links_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let links_body_url_lens : @lens.Lens[String?] = @lens.root()
  .string("url")
  .optional()

///|
let links_body_html_lens : @lens.Lens[String?] = @lens.root()
  .string("html")
  .optional()

///|
let links_body_goto_options_lens : @lens.Lens[Json?] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
let links_body_visible_only_lens : @lens.Lens[Bool?] = @lens.root()
  .bool("visibleLinksOnly")
  .optional()

///|
let links_body_exclude_external_lens : @lens.Lens[Bool?] = @lens.root()
  .bool("excludeExternalLinks")
  .optional()

///|
impl ToJson for LinksGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  links_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend LinksGotoOptions with ToJson::{to_json}

///|
impl ToJson for LinksBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  links_body_url_lens.set_or_abort(builder, self.url)
  links_body_html_lens.set_or_abort(builder, self.html)
  links_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  links_body_visible_only_lens.set_or_abort(builder, self.visibleLinksOnly)
  links_body_exclude_external_lens.set_or_abort(
    builder,
    self.excludeExternalLinks,
  )
  builder.to_json()
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
