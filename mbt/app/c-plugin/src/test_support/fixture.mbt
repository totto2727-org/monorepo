///|
pub fn join_path(base : String, name : String) -> String {
  @path.Path::join(base, name).to_string()
}

///|
pub async fn write_text(path : String, content : String) -> Unit {
  @fs.mkdir(@path.Path::dirname(path).to_string(), recursive=true) catch {
    _ => ()
  }
  @fs.write_file(path, content, create_mode=CreateOrTruncate)
}

///|
pub async fn write_claude_marketplace(repo : String) -> Unit {
  write_text(
    join_path(repo, ".claude-plugin/marketplace.json"),
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "plugin-a", "source": "plugins/plugin-a" }
      #|  ]
      #|}
    ),
  )
}

///|
pub async fn write_codex_marketplace(repo : String) -> Unit {
  write_text(
    join_path(repo, ".agents/plugins/marketplace.json"),
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "plugin-a", "source": { "path": "./plugins/plugin-a", "source": "local" } }
      #|  ]
      #|}
    ),
  )
}

///|
pub async fn write_skill(repo : String, name : String) -> Unit {
  write_text(
    join_path(repo, "plugins/plugin-a/skills/\{name}/SKILL.md"),
    "# \{name}\n",
  )
}
