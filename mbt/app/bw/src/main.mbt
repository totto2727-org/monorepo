///|
fn command_defs() -> Array[@admiral.CommandDef] {
  [
    content_command_def(),
    markdown_command_def(),
    screenshot_command_def(),
    snapshot_command_def(),
    pdf_command_def(),
    scrape_command_def(),
    json_extract_command_def(),
    links_command_def(),
    crawl_command_def(),
  ]
}

///|
fn parse() -> @argparse.Matches raise {
  @argparse.Command(
    "bw",
    about="Native MoonBit CLI for Cloudflare Browser Rendering API",
    subcommands=command_defs().map(fn(cmd) { @admiral.build_command(cmd) }),
  ).parse()
}

///|
async fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("content", command)) => run_content_command(command)
    Some(("markdown", command)) => run_markdown_command(command)
    Some(("screenshot", command)) => run_screenshot(command)
    Some(("snapshot", command)) => run_snapshot(command)
    Some(("pdf", command)) => run_pdf(command)
    Some(("scrape", command)) => run_scrape(command)
    Some(("json", command)) => run_json_extract(command)
    Some(("links", command)) => run_links(command)
    Some(("crawl", crawl)) =>
      match crawl.subcommand {
        Some(("start", command)) => run_crawl_start(command)
        Some(("status", command)) => run_crawl_get(command, "", false)
        Some(("results", command)) => run_crawl_get(command, "/results", true)
        _ => raise Failure::Failure("missing crawl subcommand")
      }
    Some((name, _)) => raise Failure::Failure("unknown command: \{name}")
    None =>
      raise Failure::Failure("no command specified. Use --help for usage.")
  }
}

///|
async fn main {
  dispatch(parse())
}
