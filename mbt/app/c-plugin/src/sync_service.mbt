///|
async fn ensure_repo(source : String) -> String {
  validate_github_source(source)
  let dir = repo_cache_dir(source)
  ensure_repo_dir(dir, "https://github.com/\{source}.git", cache_root())
}

///|
async fn ensure_repo_dir(
  dir : String,
  expected_url : String,
  safety_root : String,
) -> String {
  let normalized_root = @path.Path::normalize(safety_root).to_string()
  let mut current = @path.Path::normalize(dir).to_string()
  while true {
    let kind = @fs.kind(current, follow_symlink=false) catch {
      _ => @fs.FileKind::Unknown
    }
    guard kind != @fs.FileKind::SymLink else {
      fail("Refusing symlinked repository cache path: \{current}")
    }
    if current == normalized_root {
      break
    }
    let parent = @path.Path::dirname(current).to_string()
    guard parent != current else {
      fail("Repository cache is outside its safety root: \{dir}")
    }
    current = parent
  }
  if @fs.exists(@path.Path::join(dir, ".git").to_string()) {
    let git_dir = @path.Path::join(dir, ".git").to_string()
    guard @fs.kind(git_dir, follow_symlink=false) == @fs.FileKind::Directory else {
      fail("Refusing non-directory Git metadata: \{git_dir}")
    }
    let origin = collect_or_empty("git", [
      "-C", dir, "config", "--get", "remote.origin.url",
    ])
    guard origin == expected_url else {
      fail(
        "Repository cache origin mismatch: expected \{expected_url}, got \{origin}",
      )
    }
    if collect_or_empty("git", [
        "-C", dir, "rev-parse", "--is-shallow-repository",
      ]) ==
      "true" {
      run_checked("git", ["-C", dir, "fetch", "--unshallow", "origin"])
    } else {
      run_checked("git", ["-C", dir, "fetch", "origin"])
    }
  } else {
    let parent = @path.Path::dirname(dir).to_string()
    if !@fs.exists(parent) {
      @fs.mkdir(parent, recursive=true)
    }
    run_checked("git", ["clone", expected_url, dir])
  }
  dir
}

///|
async fn update_repo_dir(dir : String) -> String {
  guard collect_or_empty("git", ["-C", dir, "status", "--porcelain"]) == "" else {
    fail("Refusing to update a dirty repository cache: \{dir}")
  }
  let default_ref = collect_or_empty("git", [
    "-C", dir, "symbolic-ref", "--short", "refs/remotes/origin/HEAD",
  ])
  let branch = if default_ref.has_prefix("origin/") {
    default_ref["origin/".length():].to_owned()
  } else {
    "main"
  }
  run_checked("git", ["-C", dir, "checkout", branch])
  run_checked("git", ["-C", dir, "pull", "--ff-only", "origin", branch])
  dir
}

///|
async fn update_repo(source : String) -> String {
  update_repo_dir(ensure_repo(source))
}

///|
async fn checkout_pinned_repo_dir(dir : String, hash : String) -> Unit {
  guard collect_or_empty("git", ["-C", dir, "status", "--porcelain"]) == "" else {
    fail("Refusing to check out a dirty repository cache: \{dir}")
  }
  run_checked("git", ["-C", dir, "checkout", "--detach", hash])
}

///|
async fn repo_dir_for(lock_path : String, repo : LockRepository) -> String {
  match repo.source_type {
    RepositoryLocal =>
      local_source_path(repo.source, @path.Path::dirname(lock_path).to_string())
    RepositoryGithub => {
      let dir = ensure_repo(repo.source)
      match repo.commit_hash {
        Some(hash) => checkout_pinned_repo_dir(dir, hash)
        None => ()
      }
      dir
    }
  }
}

///|
async fn commit_hash(repo_dir : String) -> String {
  collect_or_empty("git", ["-C", repo_dir, "rev-parse", "HEAD"])
}

///|
struct AgentsLock {
  agents : String
  lock : LockFile
}

///|
struct ResolvedRepository {
  repository : LockRepository
  skills : Array[ResolvedSkill]
}

///|
struct SyncPlan {
  resolved_repositories : Array[ResolvedRepository]
  skills : Array[ResolvedSkill]
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  values
  .iter()
  .fold(init=[], fn(unique, value) {
    if unique.contains(value) {
      unique
    } else {
      unique.iter().concat([value].iter()).collect()
    }
  })
}

///|
fn resolve_skill_dir_from_lock(agents : String, dir : String) -> String {
  let expanded = expand_home(dir)
  if @path.Path::is_absolute(expanded) {
    @path.Path::normalize(expanded).to_string()
  } else {
    @path.Path::join(
      @path.Path::dirname(lock_path_from_agents(agents)),
      expanded,
    )
    .normalize()
    .to_string()
  }
}

///|
fn managed_skill_roots(
  agents : String,
  skill_dirs : Array[String],
) -> Array[String] {
  [@path.Path::join(agents, "skills").to_string()]
  .iter()
  .concat(
    skill_dirs.iter().map(dir => resolve_skill_dir_from_lock(agents, dir)),
  )
  .collect()
  |> unique_strings
}

///|
fn repository_skill_names(
  repositories : Array[LockRepository],
) -> Array[String] {
  repositories
  .iter()
  .flat_map(repo => {
    repo.plugins.iter().flat_map(plugin => plugin.enabled_skills.iter())
  })
  .collect()
  |> unique_strings
}

///|
fn has_sync_conflicts(agents_locks : Array[AgentsLock]) -> Bool {
  let roots : Array[String] = agents_locks
    .iter()
    .flat_map(entry => {
      managed_skill_roots(entry.agents, entry.lock.skill_dirs).iter()
    })
    .collect()
  unique_strings(roots).length() != roots.length()
}

///|
async fn read_agents_locks(agents_dirs : Array[String]) -> Array[AgentsLock] {
  @async.all(
    agents_dirs.map(agents => () => { agents, lock: read_lock(agents) }),
  )
}

///|
async fn create_skill_link_in(
  root : String,
  skill_name : String,
  skill_path : String,
) -> Unit {
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true)
  }
  let link = managed_skill_link_path(root, skill_name)
  let kind = @fs.kind(link, follow_symlink=false) catch {
    _ => @fs.FileKind::Unknown
  }
  if kind == @fs.FileKind::SymLink {
    @fs.remove(link) catch {
      _ => ()
    }
  } else if @fs.exists(link) {
    fail("Refusing to replace non-symlink path: \{link}")
  }
  @fs.symlink(target=relative_path(root, skill_path), link)
}

///|
fn managed_skill_link_path(root : String, skill_name : String) -> String raise {
  guard is_safe_skill_name(skill_name) else {
    fail("Refusing unsafe managed skill name: \{skill_name}")
  }
  let normalized_root = @path.Path::normalize(root).to_string()
  let link = @path.Path::join(normalized_root, skill_name)
    .normalize()
    .to_string()
  guard @path.Path::dirname(link).to_string() == normalized_root else {
    fail("Managed skill path escapes its root: \{link}")
  }
  link
}

///|
async fn create_skill_link(
  agents : String,
  skill_dirs : Array[String],
  skill_name : String,
  skill_path : String,
) -> Unit {
  let target_roots = managed_skill_roots(agents, skill_dirs)
  @async.all(
    target_roots.map(root => {
      () => create_skill_link_in(root, skill_name, skill_path)
    }),
  )
  |> ignore
}

///|
async fn preflight_skill_links(
  agents : String,
  skill_dirs : Array[String],
  skills : Array[ResolvedSkill],
) -> Unit {
  for root in managed_skill_roots(agents, skill_dirs) {
    for skill in skills {
      let link = managed_skill_link_path(root, skill.skill_name)
      let kind = @fs.kind(link, follow_symlink=false) catch {
        _ => @fs.FileKind::Unknown
      }
      if kind != @fs.FileKind::SymLink && @fs.exists(link) {
        fail("Refusing to replace non-symlink path: \{link}")
      }
    }
  }
}

///|
async fn remove_named_skill_links(
  root : String,
  skill_names : Array[String],
) -> Unit {
  @async.all(
    skill_names.map(skill_name => {
      () => {
        let link = managed_skill_link_path(root, skill_name)
        let kind = @fs.kind(link, follow_symlink=false) catch {
          _ => @fs.FileKind::Unknown
        }
        if kind == @fs.FileKind::SymLink {
          @fs.remove(link)
        }
      }
    }),
  )
  |> ignore
}

///|
async fn remove_named_skill_links_from_roots(
  agents : String,
  skill_dirs : Array[String],
  skill_names : Array[String],
) -> Unit {
  @async.all(
    managed_skill_roots(agents, skill_dirs).map(root => {
      () => remove_named_skill_links(root, skill_names)
    }),
  )
  |> ignore
}

///|
async fn resolve_enabled_skills(
  agents : String,
  repo : LockRepository,
) -> Array[ResolvedSkill] {
  let repo_dir = repo_dir_for(lock_path_from_agents(agents), repo)
  let skills = resolve_skills(repo_dir, repo.marketplace_kind)
  let expected_skills : Array[String] = repo.plugins
    .iter()
    .flat_map(fn(plugin) { plugin.enabled_skills.iter() })
    .collect()
  skills
  .iter()
  .filter(skill => expected_skills.contains(skill.skill_name))
  .collect()
}

///|
fn deduplicate_resolved_skills(
  skills : Array[ResolvedSkill],
) -> Array[ResolvedSkill] {
  skills
  .iter()
  .fold(init=[], fn(unique, incoming) {
    unique
    .iter()
    .filter(skill => skill.skill_name != incoming.skill_name)
    .concat([incoming].iter())
    .collect()
  })
}

///|
async fn plan_sync_lock(agents : String, lock : LockFile) -> SyncPlan {
  let resolved_repositories : Array[ResolvedRepository] = @async.all(
      lock.repositories.map(repo => {
        () => {
          let skills = resolve_enabled_skills(agents, repo) catch {
            err if @async.is_being_cancelled() => raise err
            err => {
              println("Skipped \{repo.source}: \{err}")
              return None
            }
          }
          Some({ repository: repo, skills })
        }
      }),
    )
    .iter()
    .filter_map(resolved => resolved)
    .collect()
  let skills = resolved_repositories
    .iter()
    .flat_map(resolved => resolved.skills.iter())
    .collect()
    |> deduplicate_resolved_skills
  preflight_skill_links(agents, lock.skill_dirs, skills)
  { resolved_repositories, skills }
}

///|
async fn apply_sync_plan(
  agents : String,
  lock : LockFile,
  plan : SyncPlan,
) -> Unit {
  remove_named_skill_links_from_roots(
    agents,
    lock.skill_dirs,
    repository_skill_names(
      plan.resolved_repositories.map(resolved => resolved.repository),
    ),
  )
  @async.all(
    plan.skills.map(skill => {
      () => {
        create_skill_link(
          agents,
          lock.skill_dirs,
          skill.skill_name,
          skill.skill_path,
        )
      }
    }),
  )
  |> ignore
}

///|
async fn sync_lock(agents : String, lock : LockFile) -> Unit {
  apply_sync_plan(agents, lock, plan_sync_lock(agents, lock))
}

///|
async fn sync_agents_locks(agents_locks : Array[AgentsLock]) -> Unit {
  let tasks = agents_locks.map(entry => {
    () => {
      sync_lock(entry.agents, entry.lock)
      write_lock(entry.agents, entry.lock)
    }
  })
  if has_sync_conflicts(agents_locks) {
    @async.all(tasks, max_concurrent=1) |> ignore
  } else {
    @async.all(tasks) |> ignore
  }
}
