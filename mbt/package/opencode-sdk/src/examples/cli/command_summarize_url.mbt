///|
let summarize_url_argument : @admiral.PositionDef[String] = @admiral.position_string(
  "url",
  description="HTTP or HTTPS URL to summarize",
  required=true,
)

///|
struct SummarizeUrlOptions {
  url : String
}

///|
fn validated_http_url(url : String) -> String raise {
  guard url.has_prefix("https://") || url.has_prefix("http://") else {
    fail("url must start with http:// or https://")
  }
  url
}

///|
fn summarize_url_options(
  context : @admiral.Context,
) -> SummarizeUrlOptions raise {
  let url = context
    .get_string_required(summarize_url_argument)
    |> validated_http_url
  { url, }
}

///|
fn summarize_url_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="summarize-url",
    description="Fetch a web page and summarize it as Markdown",
    positionals=[summarize_url_argument],
    examples=["opencode-example summarize-url https://example.com"],
    run=Some(run),
  )
}

///|
async fn run_summarize_url(context : @admiral.Context) -> Unit {
  let options = summarize_url_options(context)
  let output = run_prompt({
    title: "URL summary",
    tool_access: WebFetchOnly,
    system:
      "Use the webfetch tool to fetch the URL supplied by the user. Summarize the page accurately as Markdown with a title, a concise overview, key points, and a source link. Do not use any tool other than webfetch. Return only Markdown.",
    text: "Fetch and summarize this URL: \{options.url}",
  })
  println(output)
}
