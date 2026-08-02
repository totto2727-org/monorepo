///|
let snapshot_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let snapshot_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let snapshot_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let snapshot_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output directory",
  env="BW_OUTPUT",
  config="output",
  required=true,
)

///|
let snapshot_full_page_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "full-page",
  description="Capture entire page",
  env="BW_FULL_PAGE",
  config="full_page",
)

///|
let snapshot_response_content_lens : @lens.PresenceLens[String] = @lens.root()
  .string("content")
  .optional()

///|
let snapshot_response_screenshot_lens : @lens.PresenceLens[String] = @lens.root()
  .string("screenshot")
  .optional()

///|
let snapshot_response_success_lens : @lens.PresenceLens[Bool] = @lens.root()
  .bool("success")
  .optional()

///|
let snapshot_response_result_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("result")
  .optional()

///|
struct SnapshotOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String
  full_page : Bool
}

///|
struct SnapshotGotoOptions {
  waitUntil : String
}

///|
struct SnapshotCaptureOptions {
  fullPage : Bool
}

///|
struct SnapshotBody {
  url : String?
  html : String?
  gotoOptions : SnapshotGotoOptions?
  screenshotOptions : SnapshotCaptureOptions?
}

///|
struct SnapshotResponseResult {
  content : String?
  screenshot : String?
}

///|
impl FromJson for SnapshotResponseResult with fn from_json(json, _path) {
  let content = snapshot_response_content_lens.get(json) catch { _ => None }
  let screenshot = snapshot_response_screenshot_lens.get(json) catch {
    _ => None
  }
  { content, screenshot }
}

///|
struct SnapshotResponse {
  success : Bool
  result : SnapshotResponseResult?
}

///|
impl FromJson for SnapshotResponse with fn from_json(json, path) {
  let success_value = snapshot_response_success_lens.get(json) catch {
    _ => None
  }
  let success = match success_value {
    Some(value) => value
    None => false
  }
  let result_value = snapshot_response_result_lens.get(json) catch { _ => None }
  let result = match result_value {
    Some(value) =>
      Some(
        (
          @json.from_json(
            value,
            path=snapshot_response_result_lens.add_to_json_path(path),
          ) : SnapshotResponseResult),
      )
    None => None
  }
  { success, result }
}

///|
let snapshot_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let snapshot_capture_full_page_lens : @lens.Lens[Bool] = @lens.root().bool(
  "fullPage",
)

///|
let snapshot_body_url_lens : @lens.PresenceLens[String] = @lens.root()
  .string("url")
  .optional()

///|
let snapshot_body_html_lens : @lens.PresenceLens[String] = @lens.root()
  .string("html")
  .optional()

///|
let snapshot_body_goto_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
let snapshot_body_screenshot_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("screenshotOptions")
  .optional()

///|
impl ToJson for SnapshotGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  snapshot_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend SnapshotGotoOptions with ToJson::{to_json}

///|
impl ToJson for SnapshotCaptureOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  snapshot_capture_full_page_lens.set_or_abort(builder, self.fullPage)
  builder.to_json()
}

///|
extend SnapshotCaptureOptions with ToJson::{to_json}

///|
impl ToJson for SnapshotBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  snapshot_body_url_lens.set_or_abort(builder, self.url)
  snapshot_body_html_lens.set_or_abort(builder, self.html)
  snapshot_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  snapshot_body_screenshot_options_lens.set_or_abort(
    builder,
    self.screenshotOptions.map(fn(value) { value.to_json() }),
  )
  builder.to_json()
}

///|
extend SnapshotBody with ToJson::{to_json}

///|
fn snapshot_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="snapshot",
    description="Capture both HTML and screenshot",
    options=[
      account_id_option, api_token_option, snapshot_url_option, snapshot_html_option,
      snapshot_wait_until_option, snapshot_output_option, snapshot_full_page_option,
    ],
    run=Some(run),
  )
}

///|
async fn snapshot_options(context : @admiral.Context) -> SnapshotOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(snapshot_url_option),
    html: read_optional_file(context.get_string(snapshot_html_option)),
    wait_until: context.get_string(snapshot_wait_until_option),
    output: context.get_string_required(snapshot_output_option),
    full_page: context.get_bool(snapshot_full_page_option),
  }
}

///|
fn SnapshotBody::from_options(
  options : SnapshotOptionsInput,
) -> SnapshotBody raise {
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
  }
}

///|
fn snapshot_result(data : &@io.Data) -> (String, Bytes) raise {
  let document = @json.parse(data.text()) catch {
    error => fail("Invalid snapshot response JSON: \{error}")
  }
  let response : SnapshotResponse = @json.from_json(document) catch {
    _ => fail("Invalid snapshot response")
  }
  guard response.success else { fail("Invalid snapshot response") }
  let result = match response.result {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let content = match result.content {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let screenshot = match result.screenshot {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let screenshot_bytes = @base64.std_decode2bytes(screenshot) catch {
    error => fail("Invalid snapshot screenshot data: \{error}")
  }
  (content, screenshot_bytes)
}

///|
async fn run_snapshot(context : @admiral.Context) -> Unit {
  let options = snapshot_options(context)
  let body = SnapshotBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/snapshot",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  let (content, screenshot) = snapshot_result(data)
  write_snapshot(options.output, content, screenshot)
}
