///|
let pdf_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env=url_config_env,
)

///|
let pdf_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env=html_config_env,
)

///|
let pdf_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env=wait_until_config_env,
)

///|
let pdf_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env=output_config_env,
  required=true,
)

///|
let pdf_landscape_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "landscape",
  description="Landscape orientation",
  env=landscape_config_env,
)

///|
let pdf_format_option : @admiral.OptionDef[String] = @admiral.string(
  "format",
  description="Page format",
  env=format_config_env,
)

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
      account_id_option, api_token_option, pdf_url_option, pdf_html_option, pdf_wait_until_option,
      pdf_output_option, pdf_landscape_option, pdf_format_option,
    ],
    run=Some(run),
  )
}

///|
async fn pdf_options(context : @admiral.Context) -> PdfOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(pdf_url_option),
    html: read_optional_file(context.get_string(pdf_html_option)),
    wait_until: context.get_string(pdf_wait_until_option),
    output: context.get_string_required(pdf_output_option),
    landscape: context.get_bool(pdf_landscape_option),
    format: context.get_string(pdf_format_option),
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
async fn run_pdf(context : @admiral.Context) -> Unit {
  let options = pdf_options(context)
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
