///|
test "config_loader_args - keeps only the global config option" {
  let parsed = config_loader_args([
    "bw", "screenshot", "--url", "https://example.com", "--config=custom.json", "--output",
    "capture.png",
  ])
  debug_inspect(parsed.argv, content="[\"load\", \"--config=custom.json\"]")
  inspect(parsed.explicit_path, content="true")
}

///|
test "config_loader_args - ignores config-looking values after terminator" {
  let parsed = config_loader_args([
    "bw", "content", "--", "--config", "ignored.json",
  ])
  debug_inspect(parsed.argv, content="[\"load\"]")
  inspect(parsed.explicit_path, content="false")
}
