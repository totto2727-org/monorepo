///|
let screenshot_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env=url_config_env,
)

///|
let screenshot_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env=html_config_env,
)

///|
let screenshot_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env=wait_until_config_env,
)

///|
let screenshot_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env=output_config_env,
  required=true,
)

///|
let screenshot_full_page_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "full-page",
  description="Capture entire page",
  env=full_page_config_env,
)

///|
let screenshot_width_option : @admiral.OptionDef[Int] = @admiral.int(
  "width",
  description="Viewport width",
  env=width_config_env,
)

///|
let screenshot_height_option : @admiral.OptionDef[Int] = @admiral.int(
  "height",
  description="Viewport height",
  env=height_config_env,
)

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
fn screenshot_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="screenshot",
    description="Capture a screenshot",
    options=[
      account_id_option, api_token_option, screenshot_url_option, screenshot_html_option,
      screenshot_wait_until_option, screenshot_output_option, screenshot_full_page_option,
      screenshot_width_option, screenshot_height_option,
    ],
    run=Some(run),
  )
}

///|
async fn screenshot_options(
  context : @admiral.Context,
) -> ScreenshotOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(screenshot_url_option),
    html: read_optional_file(context.get_string(screenshot_html_option)),
    wait_until: context.get_string(screenshot_wait_until_option),
    output: context.get_string_required(screenshot_output_option),
    full_page: context.get_bool(screenshot_full_page_option),
    width: context.get_int(screenshot_width_option),
    height: context.get_int(screenshot_height_option),
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
async fn run_screenshot(context : @admiral.Context) -> Unit {
  let options = screenshot_options(context)
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
