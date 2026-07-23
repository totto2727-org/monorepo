///|
let crawl_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env=url_env,
  config="url",
)

///|
let crawl_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env=html_env,
  config="html",
)

///|
let crawl_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env=wait_until_env,
  config="wait_until",
)

///|
let crawl_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  env=output_env,
  config="output",
)

///|
let crawl_limit_option : @admiral.OptionDef[Int] = @admiral.int(
  "limit",
  description="Max pages to crawl",
  env=limit_env,
  config="limit",
)

///|
let crawl_depth_option : @admiral.OptionDef[Int] = @admiral.int(
  "depth",
  description="Max link depth",
  env=depth_env,
  config="depth",
)

///|
let crawl_format_option : @admiral.OptionDef[Array[String]] = @admiral.strings(
  "format",
  description="Output formats: html,markdown,json",
  env=formats_env,
  config="formats",
)

///|
let crawl_id_option : @admiral.OptionDef[String] = @admiral.string(
  "id",
  description="Crawl job ID",
  env=id_env,
  config="id",
  required=true,
)

///|
struct CrawlStartOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String?
  limit : Int?
  depth : Int?
  formats : Array[String]?
}

///|
struct CrawlGetOptionsInput {
  account_id : String
  api_token : String
  id : String
  output : String?
}

///|
struct CrawlGotoOptions {
  waitUntil : String
}

///|
struct CrawlStartBody {
  url : String?
  html : String?
  gotoOptions : CrawlGotoOptions?
  limit : Int?
  depth : Int?
  formats : Array[String]?
}

///|
impl ToJson for CrawlGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend CrawlGotoOptions with ToJson::{to_json}

///|
impl ToJson for CrawlStartBody with fn to_json(self) -> Json {
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
    "limit",
    match self.limit {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "depth",
    match self.depth {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "formats",
    match self.formats {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
extend CrawlStartBody with ToJson::{to_json}

///|
fn crawl_command_def(
  run_start : async (@admiral.Context) -> Unit,
  run_status : async (@admiral.Context) -> Unit,
  run_results : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(name="crawl", description="Manage async crawl jobs", subcommands=[
    @admiral.command(
      name="start",
      description="Start a crawl job",
      options=[
        account_id_option, api_token_option, crawl_url_option, crawl_html_option,
        crawl_wait_until_option, crawl_output_option, crawl_limit_option, crawl_depth_option,
        crawl_format_option,
      ],
      run=Some(run_start),
    ),
    @admiral.command(
      name="status",
      description="Check crawl job status",
      options=[account_id_option, api_token_option, crawl_id_option],
      run=Some(run_status),
    ),
    @admiral.command(
      name="results",
      description="Retrieve crawl results",
      options=[
        account_id_option, api_token_option, crawl_id_option, crawl_output_option,
      ],
      run=Some(run_results),
    ),
  ])
}

///|
fn split_csv(value : String) -> Array[String] {
  value.split(",").map(fn(item) { item.to_owned() }).collect()
}

///|
async fn crawl_start_options(
  context : @admiral.Context,
) -> CrawlStartOptionsInput {
  let format_values = context.get_strings(crawl_format_option)
  let formats : Array[String] = format_values
    .iter()
    .flat_map(fn(value) { split_csv(value).iter() })
    .collect()
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(crawl_url_option),
    html: read_optional_file(context.get_string(crawl_html_option)),
    wait_until: context.get_string(crawl_wait_until_option),
    output: context.get_string(crawl_output_option),
    limit: context.get_int(crawl_limit_option),
    depth: context.get_int(crawl_depth_option),
    formats: if formats.is_empty() {
      None
    } else {
      Some(formats)
    },
  }
}

///|
fn CrawlStartBody::from_options(
  options : CrawlStartOptionsInput,
) -> CrawlStartBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    limit: options.limit,
    depth: options.depth,
    formats: options.formats,
  }
}

///|
async fn run_crawl_start(context : @admiral.Context) -> Unit {
  let options = crawl_start_options(context)
  let body = CrawlStartBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/crawl",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_text_or_stdout(options.output, data.text())
}

///|
fn crawl_get_options(context : @admiral.Context) -> CrawlGetOptionsInput raise {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    id: context.get_string_required(crawl_id_option),
    output: context.get_string(crawl_output_option),
  }
}

///|
async fn run_crawl_get(
  context : @admiral.Context,
  suffix : String,
  output : Bool,
) -> Unit {
  let options = crawl_get_options(context)
  let (code, reason, data) = get_json(
    options.account_id,
    options.api_token,
    "/crawl/\{options.id}\{suffix}",
  )
  ensure_success(code, reason, data)
  if output {
    write_text_or_stdout(options.output, data.text())
  } else {
    println(data.text())
  }
}

///|
async fn run_crawl_status(context : @admiral.Context) -> Unit {
  run_crawl_get(context, "", false)
}

///|
async fn run_crawl_results(context : @admiral.Context) -> Unit {
  run_crawl_get(context, "/results", true)
}
