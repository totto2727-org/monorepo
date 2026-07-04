///|
async fn ensure_repo(source : String) -> String {
  validate_github_source(source)
  let dir = repo_cache_dir(source)
  if @fs.exists("\{dir}/.git") {
    run_checked("git", ["-C", dir, "fetch", "--depth", "1", "origin"])
  } else {
    @fs.mkdir(dirname(dir), recursive=true)
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
    RepositoryLocal => local_source_path(repo.source, dirname(lock_path))
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
async fn create_skill_link(
  agents : String,
  skill_dirs : Array[String],
  skill_name : String,
  skill_path : String,
) -> Unit {
  let target_roots : Array[String] = ["\{agents}/skills"]
  for extra in skill_dirs {
    target_roots.push(expand_home(extra))
  }
  for root in target_roots {
    if !@fs.exists(root) {
      @fs.mkdir(root, recursive=true)
    }
    let link = "\{root}/\{skill_name}"
    let kind = @fs.kind(link, follow_symlink=false) catch {
      _ => @fs.FileKind::Unknown
    }
    if kind == @fs.FileKind::SymLink {
      @fs.remove(link) catch {
        _ => ()
      }
    } else if @fs.exists(link) {
      raise Failure::Failure("Refusing to replace non-symlink path: \{link}")
    }
    @fs.symlink(target=skill_path, link)
  }
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
  for entry in entries {
    let path = "\{root}/\{entry}"
    let kind = @fs.kind(path, follow_symlink=false) catch {
      _ => @fs.FileKind::Unknown
    }
    if kind == @fs.FileKind::SymLink {
      @fs.remove(path) catch {
        _ => ()
      }
    }
  }
}

///|
async fn clear_managed_links(
  agents : String,
  skill_dirs : Array[String],
) -> Unit {
  clear_skill_links("\{agents}/skills")
  for dir in skill_dirs {
    clear_skill_links(expand_home(dir))
  }
}

///|
async fn sync_one(
  agents : String,
  lock : LockFile,
  repo : LockRepository,
) -> Unit {
  let repo_dir = repo_dir_for(lock_path_from_agents(agents), repo)
  let skills = resolve_skills(repo_dir, repo.marketplace_kind)
  for skill in skills {
    create_skill_link(
      agents,
      lock.skill_dirs,
      skill.skill_name,
      skill.skill_path,
    )
  }
}

///|
async fn sync_all(agents : String) -> Unit {
  let lock = read_lock(agents)
  clear_managed_links(agents, lock.skill_dirs)
  for repo in lock.repositories {
    sync_one(agents, lock, repo) catch {
      err => println("Skipped \{repo.source}: \{err}")
    }
  }
  write_lock(agents, lock)
}
