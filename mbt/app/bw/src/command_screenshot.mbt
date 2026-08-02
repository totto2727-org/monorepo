///|
let screenshot_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let screenshot_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let screenshot_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let screenshot_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env="BW_OUTPUT",
  config="output",
  required=true,
)

///|
let screenshot_full_page_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "full-page",
  description="Capture entire page",
  env="BW_FULL_PAGE",
  config="full_page",
)

///|
let screenshot_width_option : @admiral.OptionDef[Int] = @admiral.int(
  "width",
  description="Viewport width",
  env="BW_WIDTH",
  config="width",
)

///|
let screenshot_height_option : @admiral.OptionDef[Int] = @admiral.int(
  "height",
  description="Viewport height",
  env="BW_HEIGHT",
  config="height",
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
let screenshot_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let screenshot_capture_full_page_lens : @lens.Lens[Bool] = @lens.root().bool(
  "fullPage",
)

///|
let screenshot_viewport_width_lens : @lens.PresenceLens[Int] = @lens.root()
  .int("width")
  .optional()

///|
let screenshot_viewport_height_lens : @lens.PresenceLens[Int] = @lens.root()
  .int("height")
  .optional()

///|
let screenshot_body_url_lens : @lens.PresenceLens[String] = @lens.root()
  .string("url")
  .optional()

///|
let screenshot_body_html_lens : @lens.PresenceLens[String] = @lens.root()
  .string("html")
  .optional()

///|
let screenshot_body_goto_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
let screenshot_body_screenshot_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("screenshotOptions")
  .optional()

///|
let screenshot_body_viewport_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("viewport")
  .optional()

///|
impl ToJson for ScreenshotGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  screenshot_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend ScreenshotGotoOptions with ToJson::{to_json}

///|
impl ToJson for ScreenshotCaptureOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  screenshot_capture_full_page_lens.set_or_abort(builder, self.fullPage)
  builder.to_json()
}

///|
extend ScreenshotCaptureOptions with ToJson::{to_json}

///|
impl ToJson for ScreenshotViewport with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  screenshot_viewport_width_lens.set_or_abort(builder, self.width)
  screenshot_viewport_height_lens.set_or_abort(builder, self.height)
  builder.to_json()
}

///|
extend ScreenshotViewport with ToJson::{to_json}

///|
impl ToJson for ScreenshotBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  screenshot_body_url_lens.set_or_abort(builder, self.url)
  screenshot_body_html_lens.set_or_abort(builder, self.html)
  screenshot_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  screenshot_body_screenshot_options_lens.set_or_abort(
    builder,
    self.screenshotOptions.map(fn(value) { value.to_json() }),
  )
  screenshot_body_viewport_lens.set_or_abort(
    builder,
    self.viewport.map(fn(value) { value.to_json() }),
  )
  builder.to_json()
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
