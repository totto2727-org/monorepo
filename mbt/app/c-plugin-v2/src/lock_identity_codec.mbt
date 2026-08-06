///|
pub impl @json.FromJson for GitHubOwner with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  GitHubOwner(value) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for GitHubOwner with fn to_json(self) -> Json {
  self.value().to_json()
}

///|
pub impl @json.FromJson for GitHubRepositoryName with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  GitHubRepositoryName(value) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for GitHubRepositoryName with fn to_json(self) -> Json {
  self.value().to_json()
}

///|
pub impl @json.FromJson for GitHubRepository with fn from_json(json, path) {
  let route : String = @json.from_json(json, path~)
  GitHubRepository::from_route(route) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for GitHubRepository with fn to_json(self) -> Json {
  self.route().to_json()
}

///|
pub impl @json.FromJson for Target with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  Target(@path.Path(value)) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for Target with fn to_json(self) -> Json {
  self.path().to_string().to_json()
}

///|
pub impl @json.FromJson for RelativeSourcePath with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  RelativeSourcePath(@path.Path(value)) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for RelativeSourcePath with fn to_json(self) -> Json {
  self.path().to_string().to_json()
}

///|
pub impl @json.FromJson for RelativePluginPath with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  RelativePluginPath(@path.Path(value)) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for RelativePluginPath with fn to_json(self) -> Json {
  self.path().to_string().to_json()
}

///|
pub impl @json.FromJson for PluginName with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  PluginName(value) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for PluginName with fn to_json(self) -> Json {
  self.value().to_json()
}

///|
pub impl @json.FromJson for SkillName with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  SkillName(value) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for SkillName with fn to_json(self) -> Json {
  self.value().to_json()
}

///|
pub impl @json.FromJson for CommitId with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  CommitId(value) catch {
    error => raise @json.JsonDecodeError((path, error.to_string()))
  }
}

///|
pub impl ToJson for CommitId with fn to_json(self) -> Json {
  self.value().to_json()
}
