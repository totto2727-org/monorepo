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
extend ScreenshotGotoOptions with ToJson::{to_json}

///|
impl ToJson for ScreenshotCaptureOptions with fn to_json(self) -> Json {
  Json::object({ "fullPage": self.fullPage.to_json() })
}

///|
extend ScreenshotCaptureOptions with ToJson::{to_json}

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
extend ScreenshotViewport with ToJson::{to_json}

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
extend ScreenshotBody with ToJson::{to_json}

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
    ),
    @admiral.bool(
      screenshot_full_page_option,
      description="Capture entire page",
    ),
    @admiral.int(screenshot_width_option, description="Viewport width"),
    @admiral.int(screenshot_height_option, description="Viewport height"),
    @admiral.string(config_option, description="Path to JSON config file"),
  ])
}

///|
async fn screenshot_options(
  matches : @argparse.Matches,
) -> ScreenshotOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, screenshot_url_option), config.url),
    html: merged_html(matches, screenshot_html_option, config),
    wait_until: merge_string(
      cli_string(matches, screenshot_wait_until_option),
      config.wait_until,
    ),
    output: required_value(
      "output",
      merge_string(cli_string(matches, screenshot_output_option), config.output),
    ),
    full_page: merge_bool(
      matches.flags.get(screenshot_full_page_option).unwrap_or(false),
      config.full_page,
      false,
    ),
    width: merge_int(cli_int(matches, screenshot_width_option), config.width),
    height: merge_int(cli_int(matches, screenshot_height_option), config.height),
  }
}

///|
fn ScreenshotBody::from_options(
  options : ScreenshotOptionsInput,
) -> ScreenshotBody raise {
  required_body_source(options.url, options.html)
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
