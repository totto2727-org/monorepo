///|

///|
struct LockPlugin {
  name : String
  path : String
  enabled_skills : Array[String]
}

///|
struct LockRepository {
  source_type : RepositorySourceType
  source : String
  marketplace_kind : MarketplaceKind
  commit_hash : String?
  plugins : Array[LockPlugin]
}

///|
enum RepositorySourceType {
  RepositoryLocal
  RepositoryGithub
}

///|
impl ToJson for LockPlugin with fn to_json(self) -> Json {
  Json::object({
    "name": self.name.to_json(),
    "path": self.path.to_json(),
    "enabledSkills": self.enabled_skills.to_json(),
  })
}

///|
impl ToJson for LockRepository with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  object.set(
    "sourceType",
    repository_source_type_to_string(self.source_type).to_json(),
  )
  object.set("source", self.source.to_json())
  match self.commit_hash {
    Some(value) => object.set("commitHash", value.to_json())
    None => ()
  }
  object.set(
    "marketplaceKind",
    marketplace_kind_to_string(self.marketplace_kind).to_json(),
  )
  object.set("plugins", self.plugins.to_json())
  Json::object(object)
}

///|
impl ToJson for LockFile with fn to_json(self) -> Json {
  Json::object({
    "version": Json::number(1.0, repr="1"),
    "skillDirs": self.skill_dirs.to_json(),
    "repositories": self.repositories.to_json(),
  })
}

///|
extend LockFile with ToJson::{to_json}

///|
fn repository_source_type_from_string(
  value : String,
) -> RepositorySourceType raise {
  match value {
    "local" => RepositoryLocal
    "github" => RepositoryGithub
    _ => fail("unsupported repository source type: \{value}")
  }
}

///|
fn repository_source_type_to_string(
  source_type : RepositorySourceType,
) -> String {
  match source_type {
    RepositoryLocal => "local"
    RepositoryGithub => "github"
  }
}

///|
fn empty_lock_file() -> LockFile {
  { skill_dirs: [], repositories: [] }
}

///|
fn lock_plugin_from_json(json : Json) -> LockPlugin? {
  let _ = @lens.root().get(json) catch { _ => return None }
  let name = @lens.root().string("name").get(json) catch { _ => "plugin" }
  let path = @lens.root().string("path").get(json) catch { _ => name }
  let enabled_skills_json = @lens.root().json("enabledSkills").array().get(json) catch {
      _ => []
    }
  let enabled_skills = strings_from_json_array(enabled_skills_json)
  Some({ name, path, enabled_skills })
}

///|
fn strings_from_json_array(values : Array[Json]) -> Array[String] {
  values
  .iter()
  .filter_map(value => {
    match value {
      Json::String(text) => Some(text)
      _ => None
    }
  })
  .collect()
}

///|
fn lock_plugins_from_json(json : Array[Json]) -> Array[LockPlugin] {
  json.iter().filter_map(lock_plugin_from_json).collect()
}

///|
fn repositories_from_json_array(values : Array[Json]) -> Array[LockRepository] {
  values
  .iter()
  .filter_map(fn(value) { lock_repository_from_json(value) catch { _ => None } })
  .collect()
}

///|
fn lock_repository_from_json(json : Json) -> LockRepository? raise {
  let _ = @lens.root().get(json) catch { _ => return None }
  let source = @lens.root().string("source").get(json) catch { _ => "" }
  guard source != "" else { return None }
  let source_type = @lens.root().string("sourceType").get(json) catch {
      _ => "local"
    }
  let marketplace_kind = @lens.root().string("marketplaceKind").get(json) catch {
      _ => "claude"
    }
  let commit_hash = @lens.root().string("commitHash").optional().get(json) catch {
      _ => None
    }
  let plugins_json = @lens.root().json("plugins").array().get(json) catch {
      _ => []
    }
  let plugins = lock_plugins_from_json(plugins_json)
  Some({
    source_type: repository_source_type_from_string(source_type),
    source,
    marketplace_kind: marketplace_kind_from_string(marketplace_kind),
    commit_hash,
    plugins,
  })
}

///|
struct LockFile {
  skill_dirs : Array[String]
  repositories : Array[LockRepository]
}

///|
fn empty_lock_text() -> String {
  empty_lock_file().to_json().stringify(indent=2) + "\n"
}

///|
async fn ensure_lock(agents : String) -> Unit {
  if !@fs.exists(agents) {
    @fs.mkdir(agents, recursive=true)
  }
  let path = lock_path_from_agents(agents)
  if !@fs.exists(path) {
    @fs.write_file(path, empty_lock_text(), create_mode=CreateOrTruncate)
  }
}

///|
async fn read_lock(agents : String) -> LockFile {
  let path = lock_path_from_agents(agents)
  let text = if @fs.exists(path) {
    @fs.read_file(path).text()
  } else {
    empty_lock_text()
  }
  let document = @json.parse(text) catch { _ => return empty_lock_file() }
  let version = @lens.root().number("version").get(document) catch { _ => 0.0 }
  guard version == 1.0 else { return empty_lock_file() }
  let skill_dirs_json = @lens.root().json("skillDirs").array().get(document) catch {
      _ => []
    }
  let repositories_json = @lens.root()
    .json("repositories")
    .array()
    .get(document) catch {
      _ => []
    }
  let skill_dirs = strings_from_json_array(skill_dirs_json)
  let repositories = repositories_from_json_array(repositories_json)
  { skill_dirs, repositories }
}

///|
async fn write_lock(agents : String, lock : LockFile) -> Unit {
  @fs.write_file(
    lock_path_from_agents(agents),
    lock.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
  )
}
