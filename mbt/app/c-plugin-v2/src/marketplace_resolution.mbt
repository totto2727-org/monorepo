///|
pub struct ResolvedSkill {
  plugin_name : PluginName
  plugin_path : RelativePluginPath
  skill_name : SkillName
  skill_path : @path.Path
} derive(Eq)

///|
pub(all) suberror SkillResolutionError {
  RelativeRepositoryRoot(path~ : @path.Path)
  IO(path~ : @path.Path, reason~ : String)
  InvalidSkillName(path~ : @path.Path, reason~ : String)
} derive(Debug, Eq)

///|
pub async fn resolve_marketplace_skills(
  repository_root : @path.Path,
  marketplace : Marketplace,
) -> ReadOnlyArray[ResolvedSkill] raise SkillResolutionError {
  guard repository_root.is_absolute() else {
    raise RelativeRepositoryRoot(path=repository_root)
  }
  let normalized_root = repository_root.normalize()
  let resolved = []
  for plugin in marketplace.plugins {
    let plugin_skills = resolve_plugin_skills(normalized_root, plugin)
    resolved.push_iter(plugin_skills.iter())
  }
  ReadOnlyArray::from_array(resolved)
}

///|
async fn resolve_plugin_skills(
  repository_root : @path.Path,
  plugin : MarketplacePlugin,
) -> Array[ResolvedSkill] raise SkillResolutionError {
  let skills_directory = repository_root.join(plugin.path.path).join("skills")
  let entries = @fs.readdir(
    skills_directory.to_string(),
    include_hidden=false,
    include_special=false,
    sort=false,
  ) catch {
    @os_error.OSError(_) as error if error.is_ENOENT() => return []
    error => raise IO(path=skills_directory, reason=error.to_string())
  }
  let candidates : Array[(SkillName, @path.Path)] = []
  for entry in entries {
    let candidate_path = skills_directory.join(entry)
    let marker_path = candidate_path.join("SKILL.md")
    let has_marker = @fs.exists(marker_path.to_string()) catch {
      @os_error.OSError(_) as error if error.is_ENOENT() || error.is_ENOTDIR() =>
        false
      error => raise IO(path=marker_path, reason=error.to_string())
    }
    if has_marker {
      let skill_name = SkillName::SkillName(entry) catch {
        error =>
          raise InvalidSkillName(path=candidate_path, reason=error.to_string())
      }
      candidates.push((skill_name, candidate_path))
    }
  }
  candidates.sort_by((left, right) => left.0.compare(right.0))
  candidates.map(candidate => {
    plugin_name: plugin.name,
    plugin_path: plugin.path,
    skill_name: candidate.0,
    skill_path: candidate.1,
  })
}
