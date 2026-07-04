///|
let base_kind_arg = "base-kind"

///|
fn dev_marketplace_sync_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="sync",
    description="Regenerate marketplace manifests from a base kind",
    positionals=[
      @admiral.positional(base_kind_arg, description="claude, cursor, or codex"),
    ],
  )
}

///|
struct DevMarketplaceSyncOptions {
  kind : MarketplaceKind
}

///|
struct ParsedMarketplace {
  name : String
  plugins : Array[NormalizedPlugin]
}

///|
fn dev_marketplace_sync_options(
  matches : @argparse.Matches,
) -> DevMarketplaceSyncOptions raise {
  let values = matches.values
    .get(base_kind_arg)
    .unwrap_or_error(Failure::Failure("base kind is required"))
  let value = match values {
    [value, ..] => value
    [] => raise Failure::Failure("base kind is required")
  }
  let kind = marketplace_kind_from_string(value)
  { kind, }
}

///|
fn parse_marketplace(
  text : String,
  kind : MarketplaceKind,
) -> ParsedMarketplace {
  let name = quoted_value(text, "name", 0).unwrap_or("marketplace")
  let plugins : Array[NormalizedPlugin] = []
  let mut cursor = 0
  while cursor < text.length() {
    match text[cursor:].find(source_key(kind)) {
      Some(found) => {
        let object_start = cursor + found
        let plugin_name = previous_quoted_value(text, "name", object_start).unwrap_or(
          "plugin",
        )
        let description = previous_quoted_value(
          text, "description", object_start,
        )
        let source = source_value(text, object_start, kind).unwrap_or(
          plugin_name,
        )
        plugins.push({ name: plugin_name, source, description })
        cursor = object_start + 8
        continue
      }
      None => break
    }
  }
  { name, plugins }
}

///|
fn description_json(description : String?) -> String {
  match description {
    Some(value) => "\n      \"description\": \"\{json_escape(value)}\","
    None => ""
  }
}

///|
fn marketplace_json(
  marketplace : ParsedMarketplace,
  kind : MarketplaceKind,
) -> String {
  let plugins : Array[String] = []
  for plugin in marketplace.plugins {
    match kind {
      Codex => {
        let entry = "    {\n" +
          "      \"category\": \"Productivity\",\n" +
          "      \"name\": \"\{json_escape(plugin.name)}\",\n" +
          "      \"policy\": {\n" +
          "        \"authentication\": \"ON_INSTALL\",\n" +
          "        \"installation\": \"AVAILABLE\"\n" +
          "      },\n" +
          "      \"source\": {\n" +
          "        \"path\": \"./\{json_escape(plugin.source)}\",\n" +
          "        \"source\": \"local\"\n" +
          "      }\n" +
          "    }"
        plugins.push(entry)
      }
      _ => {
        let entry = "    {" +
          description_json(plugin.description) +
          "\n" +
          "      \"name\": \"\{json_escape(plugin.name)}\",\n" +
          "      \"source\": \"\{json_escape(plugin.source)}\"\n" +
          "    }"
        plugins.push(entry)
      }
    }
  }
  "{\n" +
  "  \"name\": \"\{json_escape(marketplace.name)}\",\n" +
  "  \"plugins\": [\n" +
  plugins.join(",\n") +
  "\n" +
  "  ]\n" +
  "}\n"
}

///|
async fn write_json_file(path : String, text : String) -> Unit {
  @fs.mkdir(dirname(path), recursive=true)
  @fs.write_file(path, text, create_mode=CreateOrTruncate)
}

///|
async fn sync_plugin_json(
  repo_dir : String,
  base_kind : MarketplaceKind,
  target_kind : MarketplaceKind,
  plugin_source : String,
) -> Unit {
  let base_path = "\{repo_dir}/\{plugin_source}/\{marketplace_config_dir(base_kind)}/plugin.json"
  if @fs.exists(base_path) {
    let target_path = "\{repo_dir}/\{plugin_source}/\{marketplace_config_dir(target_kind)}/plugin.json"
    write_json_file(target_path, @fs.read_file(base_path).text())
  }
}

///|
async fn run_dev_marketplace_sync(matches : @argparse.Matches) -> Unit {
  let options = dev_marketplace_sync_options(matches)
  let kind = options.kind
  let info = detect_marketplace(cwd()).unwrap_or_error(
    Failure::Failure("No supported marketplace found"),
  )
  guard info.kind == kind else {
    raise Failure::Failure(
      "base marketplace \{marketplace_kind_to_string(kind)} not found",
    )
  }
  let marketplace = parse_marketplace(@fs.read_file(info.path).text(), kind)
  for target_kind in marketplace_kinds() {
    if target_kind != kind {
      let path = "\{cwd()}/\{marketplace_path(target_kind)}"
      println(
        "Generating \{marketplace_kind_to_string(target_kind)} marketplace...",
      )
      write_json_file(path, marketplace_json(marketplace, target_kind))
      for plugin in marketplace.plugins {
        sync_plugin_json(cwd(), kind, target_kind, plugin.source)
      }
    }
  }
  println("Marketplace sync complete.")
}
