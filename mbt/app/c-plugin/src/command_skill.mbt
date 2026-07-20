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
  run : (@admiral.Context) -> Unit,
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
  run : (@admiral.Context) -> Unit,
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
  run : (@admiral.Context) -> Unit,
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
  run : (@admiral.Context) -> Unit,
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
  let hash = match source_type {
    RepositoryGithub => Some(commit_hash(dir))
    RepositoryLocal => None
  }
  let lock = read_lock(agents)
  let skills = resolve_skills(dir, market.kind)
  let incoming_plugins = plugins_from_skills(skills)
  let repository : LockRepository = {
    source_type,
    source,
    marketplace_kind: market.kind,
    commit_hash: hash,
    plugins: incoming_plugins,
  }
  write_lock(agents, {
    skill_dirs: lock.skill_dirs,
    repositories: upsert_repository(lock.repositories, repository),
  })
  sync_all(agents)
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
  for agents in agents_dirs {
    sync_all(agents)
  }
}

///|
async fn run_skill_update(context : @admiral.Context) -> Unit {
  let options = skill_global_options(context)
  let agents_dirs = if options.global {
    [resolve_global_agents_dir()]
  } else {
    resolve_agents_dirs(options.recursive)
  }
  for agents in agents_dirs {
    let lock = read_lock(agents)
    let updated = update_repositories(lock.repositories, 0)
    write_lock(agents, { skill_dirs: lock.skill_dirs, repositories: updated })
    sync_all(agents)
  }
}

///|
async fn update_repositories(
  repositories : Array[LockRepository],
  index : Int,
) -> Array[LockRepository] {
  if index >= repositories.length() {
    return []
  }
  let repo = repositories[index]
  let current = match repo.source_type {
    RepositoryGithub => {
      let dir = update_repo(repo.source)
      [
        {
          source_type: repo.source_type,
          source: repo.source,
          marketplace_kind: repo.marketplace_kind,
          commit_hash: Some(commit_hash(dir)),
          plugins: repo.plugins,
        },
      ]
    }
    RepositoryLocal => [repo]
  }
  let rest = update_repositories(repositories, index + 1)
  current.iter().concat(rest.iter()).collect()
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
  write_lock(agents, { skill_dirs: lock.skill_dirs, repositories })
  sync_all(agents)
  println("Removed \{source}")
}
