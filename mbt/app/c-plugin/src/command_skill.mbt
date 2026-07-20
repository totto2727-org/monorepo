///|
let global_option = "global"

///|
let local_option = "local"

///|
let recursive_option = "recursive"

///|
let repo_arg = "repo"

///|
enum SkillAddSource {
  Github(String)
  Local(String)
}

///|
struct SkillAddOptions {
  global : Bool
  source : SkillAddSource
}

///|
struct SkillGlobalOptions {
  global : Bool
  recursive : Bool
}

///|
struct SkillRemoveOptions {
  global : Bool
  source : String
}

///|
fn skill_add_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
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
    run=Some(run),
  )
}

///|
fn skill_sync_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
  @admiral.command(
    name="sync",
    description="Re-create skill symlinks",
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
      @admiral.bool(
        recursive_option,
        short='r',
        description="Sync from the nearest lock file and descendant lock files",
      ),
    ],
    run=Some(run),
  )
}

///|
fn skill_update_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
  @admiral.command(
    name="update",
    description="Update GitHub-sourced repos and sync",
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
      @admiral.bool(
        recursive_option,
        short='r',
        description="Update from the nearest lock file and descendant lock files",
      ),
    ],
    run=Some(run),
  )
}

///|
fn skill_remove_command_def(
  run : (async (@admiral.Context) -> Unit),
) -> @admiral.CommandDef {
  @admiral.command(
    name="remove",
    description="Remove a repository from the lockfile",
    positionals=[@admiral.positional(repo_arg, description="Repository source")],
    options=[
      @admiral.bool(global_option, short='g', description="Use ~/.agents"),
    ],
    run=Some(run),
  )
}

///|
fn skill_add_options(context : @admiral.Context) -> SkillAddOptions raise {
  let global = context.flags.contains(global_option)
  let local_path = match context.values.get(local_option) {
    Some([value, ..]) => Some(value)
    _ => None
  }
  let repo = match context.values.get(repo_arg) {
    Some([value, ..]) => Some(value)
    _ => None
  }
  let source = match (local_path, repo) {
    (Some(path), _) => {
      guard path.has_prefix("./") else {
        fail("--local path must start with ./")
      }
      Local(path)
    }
    (None, Some(source)) => {
      validate_github_source(source)
      Github(source)
    }
    _ => fail("Either <repo> or --local <path> must be provided")
  }
  { global, source }
}

///|
fn skill_global_options(context : @admiral.Context) -> SkillGlobalOptions {
  {
    global: context.flags.contains(global_option),
    recursive: context.flags.contains(recursive_option),
  }
}

///|
fn skill_remove_options(context : @admiral.Context) -> SkillRemoveOptions raise {
  let values = match context.values.get(repo_arg) {
    Some(values) => values
    None => fail("source is required")
  }
  let source = match values {
    [value, ..] => value
    [] => fail("source is required")
  }
  { global: context.flags.contains(global_option), source }
}

///|
async fn run_skill_add(context : @admiral.Context) -> Unit {
  let options = skill_add_options(context)
  let agents = command_agents_dir(options.global)
  ensure_lock(agents)
  let root = @path.Path::dirname(agents).to_string()
  let (source_type, source, dir) = match options.source {
    Local(path) => (RepositoryLocal, path, local_source_path(path, root))
    Github(repo) => (RepositoryGithub, repo, ensure_repo(repo))
  }
  let market = match detect_marketplace(dir) {
    Some(market) => market
    None => fail("No supported marketplace found in \{dir}")
  }
  let (hash, lock, skills) = @async.with_task_group(group => {
    let hash_task = group.spawn(() => {
      match source_type {
        RepositoryGithub => Some(commit_hash(dir))
        RepositoryLocal => None
      }
    })
    let lock_task = group.spawn(() => read_lock(agents))
    let skills_task = group.spawn(() => resolve_skills(dir, market.kind))
    (hash_task.wait(), lock_task.wait(), skills_task.wait())
  })
  let incoming_plugins = plugins_from_skills(skills)
  let repository : LockRepository = {
    source_type,
    source,
    marketplace_kind: market.kind,
    commit_hash: hash,
    plugins: incoming_plugins,
  }
  let updated_lock : LockFile = {
    skill_dirs: lock.skill_dirs,
    repositories: upsert_repository(lock.repositories, repository),
  }
  write_lock(agents, updated_lock)
  sync_lock(agents, updated_lock)
  println("Added \{source}")
}

///|
fn upsert_repository(
  repositories : Array[LockRepository],
  incoming : LockRepository,
) -> Array[LockRepository] {
  let updated = repositories.map(fn(repo) {
    if repo.source == incoming.source {
      {
        source_type: incoming.source_type,
        source: incoming.source,
        marketplace_kind: incoming.marketplace_kind,
        commit_hash: incoming.commit_hash,
        plugins: merge_plugins(repo.plugins, incoming.plugins),
      }
    } else {
      repo
    }
  })
  if repositories.any(fn(repo) { repo.source == incoming.source }) {
    updated
  } else {
    updated.iter().concat([incoming].iter()).collect()
  }
}

///|
async fn run_skill_sync(context : @admiral.Context) -> Unit {
  let options = skill_global_options(context)
  let agents_dirs = if options.global {
    [resolve_global_agents_dir()]
  } else {
    resolve_agents_dirs(options.recursive)
  }
  sync_agents_locks(read_agents_locks(agents_dirs))
}

///|
fn has_update_conflicts(agents_locks : Array[AgentsLock]) -> Bool {
  let sources : Array[String] = agents_locks
    .iter()
    .flat_map(entry => {
      entry.lock.repositories
      .iter()
      .filter_map(repo => {
        match repo.source_type {
          RepositoryGithub => Some(repo.source)
          RepositoryLocal => None
        }
      })
    })
    .collect()
  has_sync_conflicts(agents_locks) ||
  unique_strings(sources).length() != sources.length()
}

///|
async fn run_skill_update(context : @admiral.Context) -> Unit {
  let options = skill_global_options(context)
  let agents_dirs = if options.global {
    [resolve_global_agents_dir()]
  } else {
    resolve_agents_dirs(options.recursive)
  }
  let agents_locks = read_agents_locks(agents_dirs)
  let tasks = agents_locks.map(entry => () => {
    let updated_lock : LockFile = {
      skill_dirs: entry.lock.skill_dirs,
      repositories: update_repositories(entry.lock.repositories),
    }
    write_lock(entry.agents, updated_lock)
    sync_lock(entry.agents, updated_lock)
  })
  if has_update_conflicts(agents_locks) {
    @async.all(tasks, max_concurrent=1) |> ignore
  } else {
    @async.all(tasks) |> ignore
  }
}

///|
async fn update_repositories(
  repositories : Array[LockRepository],
) -> Array[LockRepository] {
  @async.all(
    repositories.map(repo => () => {
      match repo.source_type {
        RepositoryGithub => {
          let dir = update_repo(repo.source)
          {
            source_type: repo.source_type,
            source: repo.source,
            marketplace_kind: repo.marketplace_kind,
            commit_hash: Some(commit_hash(dir)),
            plugins: repo.plugins,
          }
        }
        RepositoryLocal => repo
      }
    }),
  )
}

///|
async fn run_skill_remove(context : @admiral.Context) -> Unit {
  let options = skill_remove_options(context)
  let agents = command_agents_dir(options.global)
  let source = options.source
  let lock = read_lock(agents)
  let repositories = lock.repositories
    .iter()
    .filter(fn(repo) { repo.source != source })
    .collect()
  let updated_lock : LockFile = { skill_dirs: lock.skill_dirs, repositories }
  write_lock(agents, updated_lock)
  sync_lock(agents, updated_lock)
  println("Removed \{source}")
}
