///|
pub struct MarketplacePlugin {
  name : PluginName
  path : RelativePluginPath
} derive(Eq)

///|
pub fn MarketplacePlugin::MarketplacePlugin(
  name : PluginName,
  path : RelativePluginPath,
) -> MarketplacePlugin {
  { name, path }
}

///|
pub struct Marketplace {
  name : String
  plugins : ReadOnlyArray[MarketplacePlugin]
} derive(Eq)

///|
pub fn Marketplace::Marketplace(
  name : String,
  plugins : Array[MarketplacePlugin],
) -> Marketplace raise {
  let plugin_names = @immut_hashset.HashSet(plugins.map(plugin => plugin.name))
  guard plugin_names.length() == plugins.length() else {
    fail("marketplace plugin names must be unique")
  }
  { name, plugins: ReadOnlyArray::from_array(plugins) }
}

///|
let marketplace_name_lens : @lens.Lens[Json] = @lens.root().json("name")

///|
let marketplace_plugins_lens : @lens.Lens[Json] = @lens.root().json("plugins")

///|
let marketplace_plugin_name_lens : @lens.Lens[Json] = @lens.root().json("name")

///|
let marketplace_plugin_source_lens : @lens.Lens[Json] = @lens.root().json(
  "source",
)

///|
let codex_source_kind_lens : @lens.Lens[Json] = @lens.root().json("source")

///|
let codex_source_path_lens : @lens.Lens[Json] = @lens.root().json("path")

///|
struct StringSourceMarketplaceWire {
  name : String
  plugins : Array[StringSourcePluginWire]
  plugins_path : @json.JsonPath
}

///|
impl @json.FromJson for StringSourceMarketplaceWire with fn from_json(
  json,
  path,
) {
  let name : String = @json.from_json(
    marketplace_name_lens.get_or_json_decode_error(json, path),
    path=marketplace_name_lens.add_to_json_path(path),
  )
  let plugins_path = marketplace_plugins_lens.add_to_json_path(path)
  let plugins : Array[StringSourcePluginWire] = @json.from_json(
    marketplace_plugins_lens.get_or_json_decode_error(json, path),
    path=plugins_path,
  )
  { name, plugins, plugins_path }
}

///|
struct StringSourcePluginWire {
  name : PluginName
  source : RelativePluginPath
}

///|
impl @json.FromJson for StringSourcePluginWire with fn from_json(json, path) {
  let name : PluginName = @json.from_json(
    marketplace_plugin_name_lens.get_or_json_decode_error(json, path),
    path=marketplace_plugin_name_lens.add_to_json_path(path),
  )
  let source : RelativePluginPath = @json.from_json(
    marketplace_plugin_source_lens.get_or_json_decode_error(json, path),
    path=marketplace_plugin_source_lens.add_to_json_path(path),
  )
  { name, source }
}

///|
struct CodexMarketplaceWire {
  name : String
  plugins : Array[CodexPluginWire]
  plugins_path : @json.JsonPath
}

///|
impl @json.FromJson for CodexMarketplaceWire with fn from_json(json, path) {
  let name : String = @json.from_json(
    marketplace_name_lens.get_or_json_decode_error(json, path),
    path=marketplace_name_lens.add_to_json_path(path),
  )
  let plugins_path = marketplace_plugins_lens.add_to_json_path(path)
  let plugins : Array[CodexPluginWire] = @json.from_json(
    marketplace_plugins_lens.get_or_json_decode_error(json, path),
    path=plugins_path,
  )
  { name, plugins, plugins_path }
}

///|
struct CodexPluginWire {
  name : PluginName
  source : CodexSourceWire
}

///|
impl @json.FromJson for CodexPluginWire with fn from_json(json, path) {
  let name : PluginName = @json.from_json(
    marketplace_plugin_name_lens.get_or_json_decode_error(json, path),
    path=marketplace_plugin_name_lens.add_to_json_path(path),
  )
  let source : CodexSourceWire = @json.from_json(
    marketplace_plugin_source_lens.get_or_json_decode_error(json, path),
    path=marketplace_plugin_source_lens.add_to_json_path(path),
  )
  { name, source }
}

///|
struct CodexSourceWire {
  path : RelativePluginPath
}

///|
enum CodexSourceKind {
  Local
}

///|
impl @json.FromJson for CodexSourceKind with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "local" => Local
    unsupported =>
      raise @json.JsonDecodeError(
        (path, "unsupported Codex plugin source: \{unsupported}"),
      )
  }
}

///|
impl @json.FromJson for CodexSourceWire with fn from_json(json, path) {
  let _source : CodexSourceKind = @json.from_json(
    codex_source_kind_lens.get_or_json_decode_error(json, path),
    path=codex_source_kind_lens.add_to_json_path(path),
  )
  let plugin_path : RelativePluginPath = @json.from_json(
    codex_source_path_lens.get_or_json_decode_error(json, path),
    path=codex_source_path_lens.add_to_json_path(path),
  )
  { path: plugin_path }
}

///|
pub fn Marketplace::from_json(
  kind : MarketplaceKind,
  json : Json,
) -> Marketplace raise @json.JsonDecodeError {
  match kind {
    Claude | Cursor => {
      let wire : StringSourceMarketplaceWire = @json.from_json(json)
      let plugins = wire.plugins.map(plugin => {
        MarketplacePlugin(plugin.name, plugin.source)
      })
      Marketplace(wire.name, plugins) catch {
        _ =>
          raise @json.JsonDecodeError(
            (wire.plugins_path, "marketplace plugin names must be unique"),
          )
      }
    }
    Codex => {
      let wire : CodexMarketplaceWire = @json.from_json(json)
      let plugins = wire.plugins.map(plugin => {
        MarketplacePlugin(plugin.name, plugin.source.path)
      })
      Marketplace(wire.name, plugins) catch {
        _ =>
          raise @json.JsonDecodeError(
            (wire.plugins_path, "marketplace plugin names must be unique"),
          )
      }
    }
  }
}
