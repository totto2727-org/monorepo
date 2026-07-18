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
    (repo
    |> @path.Path::join(".claude-plugin")
    |> @path.Path::join("marketplace.json")).to_string(),
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
    (repo
    |> @path.Path::join(".agents")
    |> @path.Path::join("plugins")
    |> @path.Path::join("marketplace.json")).to_string(),
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
    (repo
    |> @path.Path::join("plugins")
    |> @path.Path::join("plugin-a")
    |> @path.Path::join("skills")
    |> @path.Path::join(name)
    |> @path.Path::join("SKILL.md")).to_string(),
    "# \{name}\n",
  )
}
