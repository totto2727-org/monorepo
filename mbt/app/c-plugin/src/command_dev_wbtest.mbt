///|
test "marketplace sync converts Claude marketplace to Codex format" {
  let marketplace = parse_marketplace(
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "plugin-a", "description": "Plugin A", "source": "plugins/plugin-a" }
      #|  ]
      #|}
    ),
    Claude,
  )
  inspect(
    marketplace_json(marketplace, Codex),
    content=(
        #|{
        #|  "name": "test-marketplace",
        #|  "plugins": [
        #|    {
        #|      "category": "Productivity",
        #|      "name": "plugin-a",
        #|      "policy": {
        #|        "authentication": "ON_INSTALL",
        #|        "installation": "AVAILABLE"
        #|      },
        #|      "source": {
        #|        "path": "./plugins/plugin-a",
        #|        "source": "local"
        #|      }
        #|    }
        #|  ]
        #|}
      ) +
      "\n",
  )
}

///|
test "marketplace sync converts Codex marketplace to Claude format" {
  let marketplace = parse_marketplace(
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "plugin-a", "source": { "path": "./plugins/plugin-a", "source": "local" } }
      #|  ]
      #|}
    ),
    Codex,
  )
  inspect(
    marketplace_json(marketplace, Claude),
    content=(
        #|{
        #|  "name": "test-marketplace",
        #|  "plugins": [
        #|    {
        #|      "name": "plugin-a",
        #|      "source": "plugins/plugin-a"
        #|    }
        #|  ]
        #|}
      ) +
      "\n",
  )
}

///|
async test "marketplace sync copies plugin json to target kind config dir" {
  let root = @fs.tmpdir(prefix="c-plugin-plugin-json-")
  let source = "plugins/plugin-a"
  let base_path = @test_support.join_path(
    root, "plugins/plugin-a/.claude-plugin/plugin.json",
  )
  @test_support.write_text(base_path, "{\n  \"name\": \"plugin-a\"\n}\n")
  sync_plugin_json(root, Claude, Codex, source)
  let target_path = @test_support.join_path(
    root, "plugins/plugin-a/.codex-plugin/plugin.json",
  )
  assert_true(@fs.exists(target_path))
  inspect(
    @fs.read_file(target_path).text(),
    content="{\n  \"name\": \"plugin-a\"\n}\n",
  )
  @fs.rmdir(root, recursive=true)
}
