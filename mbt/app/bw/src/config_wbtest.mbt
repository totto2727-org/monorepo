///|
async test "load_config - reads an explicitly selected config file" {
  let config = load_config(process_args=[
    "bw", "markdown", "--config", "src/testdata/config.json",
  ])
  assert_eq(config.get("url"), Some("https://example.com".to_json()))
  assert_eq(config.get("full_page"), Some(false.to_json()))
  assert_eq(config.get("width"), Some((1024).to_json()))
  assert_eq(config.get("formats"), Some(["html", "markdown"].to_json()))
  assert_eq(
    config.get("custom_object"),
    Some(Json::object({ "enabled": true.to_json() })),
  )
  assert_eq(config.get("custom_null"), Some(Json::null()))
}

///|
async test "config keys and environment names resolve independently" {
  let captured = Ref("")
  let app = @admiral.cli(
    name="test-app",
    load_config=Some(fn() { { "url": "config-url".to_json() } }),
    commands=[
      @admiral.command(
        name="show",
        options=[content_url_option],
        run=Some(ctx => {
          captured.val = ctx.get_string_required(content_url_option)
        }),
      ),
    ],
  )
  app.run(argv=Some(["show"]), env=Map([]))
  inspect(captured.val, content="config-url")
  app.run(argv=Some(["show"]), env={ "BW_URL": "env-url" })
  inspect(captured.val, content="env-url")
}

///|
async test "load_config - missing default file produces empty values" {
  let config = load_config(process_args=["bw", "markdown"])
  assert_eq(config.length(), 0)
}

///|
async test "load_config - missing explicit file raises" {
  let mut raised = false
  (load_config(process_args=[
    "bw", "markdown", "--config", "src/testdata/missing.json",
  ])
  |> ignore) catch {
    @admiral.ConfigLoadFailure(message) =>
      raised = message.contains("does not exist")
  }
  inspect(raised, content="true")
}
