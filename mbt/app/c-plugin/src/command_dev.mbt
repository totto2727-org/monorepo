///|
let base_kind_arg : @admiral.PositionDef[String] = @admiral.position_string(
  "base-kind",
  description="claude, cursor, or codex",
)

///|
fn dev_marketplace_sync_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="sync",
    description="Regenerate marketplace manifests from a base kind",
    positionals=[base_kind_arg],
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
let normalized_plugin_description_lens : @lens.Lens[String?] = @lens.root()
  .string("description")
  .optional()

///|
let normalized_plugin_name_lens : @lens.Lens[String] = @lens.root().string(
  "name",
)

///|
let normalized_plugin_source_lens : @lens.Lens[String] = @lens.root().string(
  "source",
)

///|
impl ToJson for NormalizedPlugin with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  normalized_plugin_description_lens.set_or_abort(builder, self.description)
  normalized_plugin_name_lens.set_or_abort(builder, self.name)
  normalized_plugin_source_lens.set_or_abort(builder, self.source)
  builder.to_json()
}

///|
extend NormalizedPlugin with ToJson::{to_json}

///|
struct CodexMarketplacePolicy {
  authentication : String
  installation : String
}

///|
let codex_policy_authentication_lens : @lens.Lens[String] = @lens.root().string(
  "authentication",
)

///|
let codex_policy_installation_lens : @lens.Lens[String] = @lens.root().string(
  "installation",
)

///|
impl ToJson for CodexMarketplacePolicy with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  codex_policy_authentication_lens.set_or_abort(builder, self.authentication)
  codex_policy_installation_lens.set_or_abort(builder, self.installation)
  builder.to_json()
}

///|
extend CodexMarketplacePolicy with ToJson::{to_json}

///|
struct CodexMarketplaceSource {
  path : String
  source : String
}

///|
let codex_source_path_lens : @lens.Lens[String] = @lens.root().string("path")

///|
let codex_source_source_lens : @lens.Lens[String] = @lens.root().string(
  "source",
)

///|
impl ToJson for CodexMarketplaceSource with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  codex_source_path_lens.set_or_abort(builder, self.path)
  codex_source_source_lens.set_or_abort(builder, self.source)
  builder.to_json()
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
let codex_plugin_category_lens : @lens.Lens[String] = @lens.root().string(
  "category",
)

///|
let codex_plugin_name_lens : @lens.Lens[String] = @lens.root().string("name")

///|
let codex_plugin_policy_lens : @lens.Lens[Json] = @lens.root().json("policy")

///|
let codex_plugin_source_lens : @lens.Lens[Json] = @lens.root().json("source")

///|
impl ToJson for CodexMarketplacePlugin with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  codex_plugin_category_lens.set_or_abort(builder, self.category)
  codex_plugin_name_lens.set_or_abort(builder, self.name)
  codex_plugin_policy_lens.set_or_abort(builder, self.policy.to_json())
  codex_plugin_source_lens.set_or_abort(builder, self.source.to_json())
  builder.to_json()
}

///|
extend CodexMarketplacePlugin with ToJson::{to_json}

///|
enum MarketplacePlugin {
  DefaultMarketplacePlugin(NormalizedPlugin)
  CodexPlugin(CodexMarketplacePlugin)
}

///|
impl ToJson for MarketplacePlugin with fn to_json(self) -> Json {
  match self {
    DefaultMarketplacePlugin(plugin) => plugin.to_json()
    CodexPlugin(plugin) => plugin.to_json()
  }
}

///|
struct MarketplaceDocument {
  name : String
  plugins : Array[MarketplacePlugin]
}

///|
let marketplace_document_name_lens : @lens.Lens[String] = @lens.root().string(
  "name",
)

///|
let marketplace_document_plugins_lens : @lens.Lens[Json] = @lens.root().json(
  "plugins",
)

///|
impl ToJson for MarketplaceDocument with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  marketplace_document_name_lens.set_or_abort(builder, self.name)
  marketplace_document_plugins_lens.set_or_abort(
    builder,
    self.plugins.to_json(),
  )
  builder.to_json()
}

///|
extend MarketplaceDocument with ToJson::{to_json}

///|
fn dev_marketplace_sync_options(
  context : @admiral.Context,
) -> DevMarketplaceSyncOptions raise {
  let value = context.get_string_required(base_kind_arg)
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
  let plugins : Array[MarketplacePlugin] = marketplace.plugins
    .iter()
    .map(fn(plugin) { marketplace_plugin(plugin, kind) })
    .collect()
  let document : MarketplaceDocument = { name: marketplace.name, plugins }
  document.to_json().stringify(indent=2) + "\n"
}

///|
fn marketplace_plugin(
  plugin : NormalizedPlugin,
  kind : MarketplaceKind,
) -> MarketplacePlugin {
  match kind {
    Codex =>
      CodexPlugin({
        category: "Productivity",
        name: plugin.name,
        policy: {
          authentication: "ON_INSTALL",
          installation: "INSTALLED_BY_DEFAULT",
        },
        source: { path: "./\{plugin.source}", source: "local" },
      })
    _ =>
      DefaultMarketplacePlugin({
        name: plugin.name,
        source: "./\{plugin.source}",
        description: plugin.description,
      })
  }
}

///|
async fn write_json_file(path : String, text : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if !@fs.exists(parent) {
    @fs.mkdir(parent, recursive=true)
  }
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
async fn sync_marketplace_target(
  repo_dir : String,
  base_kind : MarketplaceKind,
  target_kind : MarketplaceKind,
  marketplace : ParsedMarketplace,
) -> Unit {
  let path = @path.Path::join(repo_dir, marketplace_path(target_kind)).to_string()
  println(
    "Generating \{marketplace_kind_to_string(target_kind)} marketplace...",
  )
  let plugin_sources = marketplace.plugins
    .iter()
    .map(plugin => plugin.source)
    .fold(init=[], fn(sources, source) {
      if sources.contains(source) {
        sources
      } else {
        sources.iter().concat([source].iter()).collect()
      }
    })
  let tasks : Array[async () -> Unit] = [
      () => write_json_file(path, marketplace_json(marketplace, target_kind)),
    ]
    .iter()
    .concat(
      plugin_sources
      .iter()
      .map(source => {
        () => sync_plugin_json(repo_dir, base_kind, target_kind, source)
      }),
    )
    .collect()
  @async.all(tasks) |> ignore
}

///|
async fn run_dev_marketplace_sync(context : @admiral.Context) -> Unit {
  let options = dev_marketplace_sync_options(context)
  let kind = options.kind
  let repo_dir = current_working_dir()
  let info = match detect_marketplace(repo_dir) {
    Some(info) => info
    None => fail("No supported marketplace found")
  }
  guard info.kind == kind else {
    fail("base marketplace \{marketplace_kind_to_string(kind)} not found")
  }
  let marketplace = parse_marketplace(@fs.read_file(info.path).text(), kind)
  let target_kinds = marketplace_kinds()
    .iter()
    .filter(target_kind => target_kind != kind)
    .collect()
  @async.all(
    target_kinds.map(target_kind => {
      () => sync_marketplace_target(repo_dir, kind, target_kind, marketplace)
    }),
  )
  |> ignore
  println("Marketplace sync complete.")
}
