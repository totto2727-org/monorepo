///|
async fn ensure_repo(source : String) -> String {
  validate_github_source(source)
  let dir = repo_cache_dir(source)
  if @fs.exists(@path.Path::join(dir, ".git").to_string()) {
    run_checked("git", ["-C", dir, "fetch", "--depth", "1", "origin"])
  } else {
    @fs.mkdir(@path.Path::dirname(dir).to_string(), recursive=true)
    run_checked("git", [
      "clone",
      "--depth",
      "1",
      "https://github.com/\{source}.git",
      dir,
    ])
  }
  dir
}

///|
async fn update_repo(source : String) -> String {
  let dir = ensure_repo(source)
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
async fn repo_dir_for(lock_path : String, repo : LockRepository) -> String {
  match repo.source_type {
    RepositoryLocal =>
      local_source_path(repo.source, @path.Path::dirname(lock_path).to_string())
    RepositoryGithub => {
      let dir = ensure_repo(repo.source)
      match repo.commit_hash {
        Some(hash) => run_checked("git", ["-C", dir, "checkout", hash])
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
fn managed_skill_roots(
  agents : String,
  skill_dirs : Array[String],
) -> Array[String] {
  [@path.Path::join(agents, "skills").to_string()]
  .iter()
  .concat(skill_dirs.iter().map(expand_home))
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
  let link = @path.Path::join(root, skill_name).to_string()
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
async fn clear_skill_links(root : String) -> Unit {
  let entries = @fs.readdir(
    root,
    include_hidden=false,
    include_special=false,
    sort=true,
  ) catch {
    _ => []
  }
  @async.all(
    entries.map(entry => {
      () => {
        let path = @path.Path::join(root, entry).to_string()
        let kind = @fs.kind(path, follow_symlink=false) catch {
          _ => @fs.FileKind::Unknown
        }
        if kind == @fs.FileKind::SymLink {
          @fs.remove(path) catch {
            _ => ()
          }
        }
      }
    }),
  )
  |> ignore
}

///|
async fn clear_managed_links(
  agents : String,
  skill_dirs : Array[String],
) -> Unit {
  let roots = managed_skill_roots(agents, skill_dirs)
  @async.all(roots.map(root => () => clear_skill_links(root))) |> ignore
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
async fn sync_lock(agents : String, lock : LockFile) -> Unit {
  clear_managed_links(agents, lock.skill_dirs)
  let skills = @async.all(
      lock.repositories.map(repo => {
        () => {
          resolve_enabled_skills(agents, repo) catch {
            err if @async.is_being_cancelled() => raise err
            err => {
              println("Skipped \{repo.source}: \{err}")
              []
            }
          }
        }
      }),
    )
    .iter()
    .flat_map(resolved => resolved.iter())
    .collect()
    |> deduplicate_resolved_skills
  @async.all(
    skills.map(skill => {
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
