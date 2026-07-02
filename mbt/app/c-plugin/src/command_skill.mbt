///|
let global_option = "global"

///|
let local_option = "local"

///|
let repo_arg = "repo"

///|
fn skill_add_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="add",
    description="Add a plugin marketplace",
    positionals=[
      @admiral.positional(
        repo_arg,
        description="GitHub owner/repo",
        required=false,
      ),
    ],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
      @admiral.string(
        local_option,
        description="Local marketplace root beginning with ./",
      ),
    ],
  )
}

///|
fn skill_sync_command_def() -> @admiral.CommandDef {
  @admiral.command(name="sync", description="Re-create skill symlinks", options=[
    @admiral.bool(global_option, short='g', description="Use ~/.agents"),
  ])
}

///|
fn skill_update_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="update",
    description="Update GitHub-sourced repos and sync",
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
  )
}

///|
fn skill_remove_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="remove",
    description="Remove a repository from the lockfile",
    positionals=[@admiral.positional(repo_arg, description="Repository source")],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
  )
}

///|
async fn run_skill_add(matches : @argparse.Matches) -> Unit {
  let global = matches.flags.contains(global_option)
  let agents = agents_dir(global)
  ensure_lock(agents)
  let root = dirname(agents)
  let local_path = match matches.values.get(local_option) {
    Some([value, ..]) => value
    _ => ""
  }
  let repo = match matches.values.get(repo_arg) {
    Some([value, ..]) => value
    _ => ""
  }
  let (source_type, source, dir) = if local_path != "" {
    guard local_path.has_prefix("./") else {
      fail("--local path must start with ./")
    }
    ("local", local_path, local_source_path(local_path, root))
  } else {
    guard repo != "" else {
      fail("Either <repo> or --local <path> must be provided")
    }
    validate_github_source(repo)
    let dir = ensure_repo(repo)
    ("github", repo, dir)
  }
  let market = detect_marketplace(dir).unwrap_or_else(() => {
    fail("No supported marketplace found in \{dir}")
  })
  let hash = if source_type == "github" { Some(commit_hash(dir)) } else { None }
  let lock = read_lock(agents)
  lock.repositories.push({
    source_type,
    source,
    marketplace_kind: market.kind,
    commit_hash: hash,
  })
  write_lock(agents, lock)
  sync_all(agents)
  println("Added \{source}")
}

///|
async fn run_skill_sync(matches : @argparse.Matches) -> Unit {
  sync_all(agents_dir(matches.flags.contains(global_option)))
}

///|
async fn run_skill_update(matches : @argparse.Matches) -> Unit {
  let agents = agents_dir(matches.flags.contains(global_option))
  let lock = read_lock(agents)
  let updated : Array[LockRepository] = []
  for repo in lock.repositories {
    if repo.source_type == "github" {
      let dir = update_repo(repo.source)
      updated.push({
        source_type: repo.source_type,
        source: repo.source,
        marketplace_kind: repo.marketplace_kind,
        commit_hash: Some(commit_hash(dir)),
      })
    } else {
      updated.push(repo)
    }
  }
  write_lock(agents, { skill_dirs: lock.skill_dirs, repositories: updated })
  sync_all(agents)
}

///|
async fn run_skill_remove(matches : @argparse.Matches) -> Unit {
  let agents = agents_dir(matches.flags.contains(global_option))
  let source = match matches.values.get(repo_arg) {
    Some([value, ..]) => value
    _ => fail("source is required")
  }
  let lock = read_lock(agents)
  let kept : Array[LockRepository] = []
  for repo in lock.repositories {
    if repo.source != source {
      kept.push(repo)
    }
  }
  write_lock(agents, { skill_dirs: lock.skill_dirs, repositories: kept })
  sync_all(agents)
  println("Removed \{source}")
}
