///|
pub(all) suberror CacheIdentityError {
  RelativePath(name~ : String, path~ : @path.Path)
  UnsupportedMetadataVersion(version~ : Int)
  MissingMetadata(expected~ : CacheScopeMetadata)
  MetadataMismatch(expected~ : CacheScopeMetadata, actual~ : CacheScopeMetadata)
} derive(Debug)

///|
let cache_scope_metadata_version_lens : @lens.Lens[Int] = @lens.root().int(
  "version",
)

///|
let cache_scope_metadata_lock_path_lens : @lens.Lens[String] = @lens.root().string(
  "lockPath",
)

///|
pub struct CacheScopeMetadata {
  version : Int
  lock_path : @path.Path
} derive(Eq, Debug)

///|
pub fn CacheScopeMetadata::CacheScopeMetadata(
  version : Int,
  lock_path : @path.Path,
) -> CacheScopeMetadata raise CacheIdentityError {
  guard version == 1 else { raise UnsupportedMetadataVersion(version~) }
  { version, lock_path: normalized_absolute_path("lock path", lock_path) }
}

///|
pub fn CacheScopeMetadata::version(self : CacheScopeMetadata) -> Int {
  self.version
}

///|
pub fn CacheScopeMetadata::lock_path(self : CacheScopeMetadata) -> @path.Path {
  self.lock_path
}

///|
pub impl FromJson for CacheScopeMetadata with fn from_json(json, path) {
  let version = cache_scope_metadata_version_lens.get_or_json_decode_error(
    json, path,
  )
  guard version == 1 else {
    raise cache_scope_metadata_version_lens.json_decode_error(
      path, "unsupported cache scope metadata version",
    )
  }
  let lock_path = cache_scope_metadata_lock_path_lens.get_or_json_decode_error(
    json, path,
  )
  CacheScopeMetadata(version, @path.Path(lock_path)) catch {
    _ =>
      raise cache_scope_metadata_lock_path_lens.json_decode_error(
        path, "cache scope lock path must be absolute",
      )
  }
}

///|
pub impl ToJson for CacheScopeMetadata with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  cache_scope_metadata_version_lens.set_or_abort(builder, self.version)
  cache_scope_metadata_lock_path_lens.set_or_abort(
    builder,
    self.lock_path.to_string(),
  )
  builder.to_json()
}

///|
pub struct CacheScope {
  lock_path : @path.Path
  scope_key : String
} derive(Eq)

///|
pub fn CacheScope::CacheScope(
  lock_path : @path.Path,
) -> CacheScope raise CacheIdentityError {
  let normalized_lock_path = normalized_absolute_path("lock path", lock_path)
  let scope_key = @sha256.sha256_hexdigest(
    @utf8.encode("lock\u{0000}\{normalized_lock_path.to_string()}"),
  )
  { lock_path: normalized_lock_path, scope_key }
}

///|
pub fn CacheScope::lock_path(self : CacheScope) -> @path.Path {
  self.lock_path
}

///|
pub fn CacheScope::scope_key(self : CacheScope) -> String {
  self.scope_key
}

///|
pub fn CacheScope::cache_path(
  self : CacheScope,
  cache_root : @path.Path,
  repository : GitHubRepository,
) -> @path.Path raise CacheIdentityError {
  normalized_absolute_path("cache root", cache_root)
  .join(self.scope_key)
  .join(repository.owner().value())
  .join(repository.name().value())
}

///|
pub fn CacheScope::metadata(self : CacheScope) -> CacheScopeMetadata {
  { version: 1, lock_path: self.lock_path }
}

///|
pub fn CacheScope::validate_metadata(
  self : CacheScope,
  metadata : CacheScopeMetadata?,
) -> Unit raise CacheIdentityError {
  let expected = self.metadata()
  match metadata {
    None => raise MissingMetadata(expected~)
    Some(actual) => {
      let matches_scope = actual == expected
      guard matches_scope else { raise MetadataMismatch(expected~, actual~) }
    }
  }
}

///|
fn normalized_absolute_path(
  name : String,
  path : @path.Path,
) -> @path.Path raise CacheIdentityError {
  guard path.is_absolute() else { raise RelativePath(name~, path~) }
  path.normalize()
}
