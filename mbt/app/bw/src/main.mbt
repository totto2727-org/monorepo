///|
async fn main {
  let app = @admiral.cli(
    name="bw",
    description="Native MoonBit CLI for Cloudflare Browser Rendering API",
    commands=[
      content_command_def(run_content_command),
      markdown_command_def(run_markdown_command),
      screenshot_command_def(run_screenshot),
      snapshot_command_def(run_snapshot),
      pdf_command_def(run_pdf),
      scrape_command_def(run_scrape),
      json_extract_command_def(run_json_extract),
      links_command_def(run_links),
      crawl_command_def(run_crawl_start, run_crawl_status, run_crawl_results),
    ],
  )
  app.run()
}
