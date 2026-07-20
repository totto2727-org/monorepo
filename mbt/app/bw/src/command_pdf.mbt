///|
let pdf_account_id_option = "account-id"

///|
let pdf_api_token_option = "api-token"

///|
let pdf_url_option = "url"

///|
let pdf_html_option = "html"

///|
let pdf_wait_until_option = "wait-until"

///|
let pdf_output_option = "output"

///|
let pdf_landscape_option = "landscape"

///|
let pdf_format_option = "format"

///|
struct PdfOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String
  landscape : Bool
  format : String?
}

///|
struct PdfGotoOptions {
  waitUntil : String
}

///|
struct PdfRenderOptions {
  landscape : Bool?
  format : String?
}

///|
struct PdfBody {
  url : String?
  html : String?
  gotoOptions : PdfGotoOptions?
  pdfOptions : PdfRenderOptions?
}

///|
impl ToJson for PdfGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend PdfGotoOptions with ToJson::{to_json}

///|
impl ToJson for PdfRenderOptions with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  put_json_if_some(
    object,
    "landscape",
    match self.landscape {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "format",
    match self.format {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
extend PdfRenderOptions with ToJson::{to_json}

///|
impl ToJson for PdfBody with fn to_json(self) -> Json {
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
    "pdfOptions",
    match self.pdfOptions {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
extend PdfBody with ToJson::{to_json}

///|
fn pdf_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="pdf",
    description="Generate a PDF",
    options=[
      @admiral.string(
        pdf_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(pdf_api_token_option, description="Cloudflare API token"),
      @admiral.string(pdf_url_option, description="Target URL"),
      @admiral.string(pdf_html_option, description="Path to local HTML file"),
      @admiral.string(pdf_wait_until_option, description="Page load strategy"),
      @admiral.string(
        pdf_output_option,
        short='o',
        description="Output file path",
      ),
      @admiral.bool(pdf_landscape_option, description="Landscape orientation"),
      @admiral.string(pdf_format_option, description="Page format"),
      @admiral.string(config_option, description="Path to JSON config file"),
    ],
    run=Some(run),
  )
}

///|
async fn pdf_options(matches : @admiral.Context) -> PdfOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, pdf_url_option), config.url),
    html: merged_html(matches, pdf_html_option, config),
    wait_until: merge_string(
      cli_string(matches, pdf_wait_until_option),
      config.wait_until,
    ),
    output: required_value(
      "output",
      merge_string(cli_string(matches, pdf_output_option), config.output),
    ),
    landscape: merge_bool(
      matches.flags.get(pdf_landscape_option).unwrap_or(false),
      config.landscape,
      false,
    ),
    format: merge_string(cli_string(matches, pdf_format_option), config.format),
  }
}

///|
fn PdfBody::from_options(options : PdfOptionsInput) -> PdfBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    pdfOptions: if options.landscape || options.format is Some(_) {
      Some({
        landscape: if options.landscape {
          Some(true)
        } else {
          None
        },
        format: options.format,
      })
    } else {
      None
    },
  }
}

///|
async fn run_pdf(matches : @admiral.Context) -> Unit {
  let options = pdf_options(matches)
  let body = PdfBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/pdf",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_binary(options.output, data, "PDF")
}
