///|
let screenshot_account_id_option = "account-id"

///|
let screenshot_api_token_option = "api-token"

///|
let screenshot_url_option = "url"

///|
let screenshot_html_option = "html"

///|
let screenshot_wait_until_option = "wait-until"

///|
let screenshot_output_option = "output"

///|
let screenshot_full_page_option = "full-page"

///|
let screenshot_width_option = "width"

///|
let screenshot_height_option = "height"

///|
struct ScreenshotOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String
  full_page : Bool
  width : Int?
  height : Int?
}

///|
struct ScreenshotGotoOptions {
  waitUntil : String
}

///|
struct ScreenshotCaptureOptions {
  fullPage : Bool
}

///|
struct ScreenshotViewport {
  width : Int?
  height : Int?
}

///|
struct ScreenshotBody {
  url : String?
  html : String?
  gotoOptions : ScreenshotGotoOptions?
  screenshotOptions : ScreenshotCaptureOptions?
  viewport : ScreenshotViewport?
}

///|
impl ToJson for ScreenshotGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for ScreenshotCaptureOptions with fn to_json(self) -> Json {
  Json::object({ "fullPage": self.fullPage.to_json() })
}

///|
impl ToJson for ScreenshotViewport with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  put_json_if_some(
    object,
    "width",
    match self.width {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "height",
    match self.height {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
impl ToJson for ScreenshotBody with fn to_json(self) -> Json {
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
    "screenshotOptions",
    match self.screenshotOptions {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "viewport",
    match self.viewport {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
fn screenshot_command_def() -> @admiral.CommandDef {
  @admiral.command(name="screenshot", description="Capture a screenshot", options=[
    @admiral.string(
      screenshot_account_id_option,
      description="Cloudflare account ID",
    ),
    @admiral.string(
      screenshot_api_token_option,
      description="Cloudflare API token",
    ),
    @admiral.string(screenshot_url_option, description="Target URL"),
    @admiral.string(
      screenshot_html_option,
      description="Path to local HTML file",
    ),
    @admiral.string(
      screenshot_wait_until_option,
      description="Page load strategy",
    ),
    @admiral.string(
      screenshot_output_option,
      short='o',
      description="Output file path",
      required=true,
    ),
    @admiral.bool(
      screenshot_full_page_option,
      description="Capture entire page",
    ),
    @admiral.int(screenshot_width_option, description="Viewport width"),
    @admiral.int(screenshot_height_option, description="Viewport height"),
  ])
}

///|
async fn screenshot_options(
  matches : @argparse.Matches,
) -> ScreenshotOptionsInput {
  {
    account_id: match matches.values.get(screenshot_account_id_option) {
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
    api_token: match matches.values.get(screenshot_api_token_option) {
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
    url: match matches.values.get(screenshot_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(screenshot_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(screenshot_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    output: {
      let values = matches.values
        .get(screenshot_output_option)
        .unwrap_or_error(Failure::Failure("missing required option: output"))
      match values {
        [value, ..] => value
        [] => raise Failure::Failure("missing required option: output")
      }
    },
    full_page: matches.flags.get(screenshot_full_page_option).unwrap_or(false),
    width: match matches.values.get(screenshot_width_option) {
      Some([value, ..]) => Some(@string.parse_int(value))
      _ => None
    },
    height: match matches.values.get(screenshot_height_option) {
      Some([value, ..]) => Some(@string.parse_int(value))
      _ => None
    },
  }
}

///|
fn ScreenshotBody::from_options(
  options : ScreenshotOptionsInput,
) -> ScreenshotBody raise {
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
    screenshotOptions: if options.full_page {
      Some({ fullPage: true })
    } else {
      None
    },
    viewport: if options.width is Some(_) || options.height is Some(_) {
      Some({ width: options.width, height: options.height })
    } else {
      None
    },
  }
}

///|
async fn run_screenshot(matches : @argparse.Matches) -> Unit {
  let options = screenshot_options(matches)
  let body = ScreenshotBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/screenshot",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_binary(options.output, data, "Screenshot")
}
