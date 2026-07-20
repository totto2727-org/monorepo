///|
let base_kind_arg = "base-kind"

///|
fn dev_marketplace_sync_command_def(
  run : (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="sync",
    description="Regenerate marketplace manifests from a base kind",
    positionals=[
      @admiral.positional(base_kind_arg, description="claude, cursor, or codex"),
    ],
    run=Some(run),
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
impl ToJson for NormalizedPlugin with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  match self.description {
    Some(value) => object.set("description", value.to_json())
    None => ()
  }
  object.set("name", self.name.to_json())
  object.set("source", self.source.to_json())
  Json::object(object)
}

///|
extend NormalizedPlugin with ToJson::{to_json}

///|
struct CodexMarketplacePolicy {
  authentication : String
  installation : String
}

///|
impl ToJson for CodexMarketplacePolicy with fn to_json(self) -> Json {
  Json::object({
    "authentication": self.authentication.to_json(),
    "installation": self.installation.to_json(),
  })
}

///|
extend CodexMarketplacePolicy with ToJson::{to_json}

///|
struct CodexMarketplaceSource {
  path : String
  source : String
}

///|
impl ToJson for CodexMarketplaceSource with fn to_json(self) -> Json {
  Json::object({ "path": self.path.to_json(), "source": self.source.to_json() })
}

///|
extend CodexMarketplaceSource with ToJson::{to_json}

///|
struct CodexMarketplacePlugin {
  category : String
  name : String
  policy : CodexMarketplacePolicy
  source : CodexMarketplaceSource
}

///|
impl ToJson for CodexMarketplacePlugin with fn to_json(self) -> Json {
  Json::object({
    "category": self.category.to_json(),
    "name": self.name.to_json(),
    "policy": self.policy.to_json(),
    "source": self.source.to_json(),
  })
}

///|
extend CodexMarketplacePlugin with ToJson::{to_json}

///|
struct MarketplaceDocument {
  name : String
  plugins : Array[Json]
}

///|
impl ToJson for MarketplaceDocument with fn to_json(self) -> Json {
  Json::object({
    "name": self.name.to_json(),
    "plugins": self.plugins.to_json(),
  })
}

///|
extend MarketplaceDocument with ToJson::{to_json}

///|
fn dev_marketplace_sync_options(
  context : @admiral.Context,
) -> DevMarketplaceSyncOptions raise {
  let values = match context.values.get(base_kind_arg) {
    Some(values) => values
    None => fail("base kind is required")
  }
  let value = match values {
    [value, ..] => value
    [] => fail("base kind is required")
  }
  let kind = marketplace_kind_from_string(value)
  { kind, }
}

///|
fn parse_marketplace(
  text : String,
  kind : MarketplaceKind,
) -> ParsedMarketplace {
  {
    name: marketplace_name_from_json(text),
    plugins: normalized_plugins_from_json(text, kind),
  }
}

///|
fn marketplace_json(
  marketplace : ParsedMarketplace,
  kind : MarketplaceKind,
) -> String {
  let plugins : Array[Json] = marketplace.plugins
    .iter()
    .map(fn(plugin) { marketplace_plugin_json(plugin, kind) })
    .collect()
  let document : MarketplaceDocument = { name: marketplace.name, plugins }
  document.to_json().stringify(indent=2) + "\n"
}

///|
fn marketplace_plugin_json(
  plugin : NormalizedPlugin,
  kind : MarketplaceKind,
) -> Json {
  match kind {
    Codex =>
      {
        category: "Productivity",
        name: plugin.name,
        policy: { authentication: "ON_INSTALL", installation: "AVAILABLE" },
        source: { path: "./\{plugin.source}", source: "local" },
      }.to_json()
    _ => plugin.to_json()
  }
}

///|
async fn write_json_file(path : String, text : String) -> Unit {
  @fs.mkdir(@path.Path::dirname(path).to_string(), recursive=true)
  @fs.write_file(path, text, create_mode=CreateOrTruncate)
}

///|
async fn sync_plugin_json(
  repo_dir : String,
  base_kind : MarketplaceKind,
  target_kind : MarketplaceKind,
  plugin_source : String,
) -> Unit {
  let base_path = (repo_dir
  |> @path.Path::join(plugin_source)
  |> @path.Path::join(marketplace_config_dir(base_kind))
  |> @path.Path::join("plugin.json")).to_string()
  if @fs.exists(base_path) {
    let target_path = (repo_dir
    |> @path.Path::join(plugin_source)
    |> @path.Path::join(marketplace_config_dir(target_kind))
    |> @path.Path::join("plugin.json")).to_string()
    write_json_file(target_path, @fs.read_file(base_path).text())
  }
}

///|
async fn run_dev_marketplace_sync(context : @admiral.Context) -> Unit {
  let options = dev_marketplace_sync_options(context)
  let kind = options.kind
  let info = match detect_marketplace(current_working_dir()) {
    Some(info) => info
    None => fail("No supported marketplace found")
  }
  guard info.kind == kind else {
    fail("base marketplace \{marketplace_kind_to_string(kind)} not found")
  }
  let marketplace = parse_marketplace(@fs.read_file(info.path).text(), kind)
  for target_kind in marketplace_kinds() {
    if target_kind != kind {
      let path = @path.Path::join(
        current_working_dir(),
        marketplace_path(target_kind),
      ).to_string()
      println(
        "Generating \{marketplace_kind_to_string(target_kind)} marketplace...",
      )
      write_json_file(path, marketplace_json(marketplace, target_kind))
      for plugin in marketplace.plugins {
        sync_plugin_json(
          current_working_dir(),
          kind,
          target_kind,
          plugin.source,
        )
      }
    }
  }
  println("Marketplace sync complete.")
}
