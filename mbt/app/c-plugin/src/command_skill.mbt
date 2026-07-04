///|
let global_option = "global"

///|
let local_option = "local"

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
}

///|
struct SkillRemoveOptions {
  global : Bool
  source : String
}

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
fn skill_add_options(matches : @argparse.Matches) -> SkillAddOptions raise {
  let global = matches.flags.contains(global_option)
  let local_path = match matches.values.get(local_option) {
    Some([value, ..]) => Some(value)
    _ => None
  }
  let repo = match matches.values.get(repo_arg) {
    Some([value, ..]) => Some(value)
    _ => None
  }
  let source = match (local_path, repo) {
    (Some(path), _) => {
      guard path.has_prefix("./") else {
        raise Failure::Failure("--local path must start with ./")
      }
      Local(path)
    }
    (None, Some(source)) => {
      validate_github_source(source)
      Github(source)
    }
    _ =>
      raise Failure::Failure("Either <repo> or --local <path> must be provided")
  }
  { global, source }
}

///|
fn skill_global_options(matches : @argparse.Matches) -> SkillGlobalOptions {
  { global: matches.flags.contains(global_option) }
}

///|
fn skill_remove_options(
  matches : @argparse.Matches,
) -> SkillRemoveOptions raise {
  let values = matches.values
    .get(repo_arg)
    .unwrap_or_error(Failure::Failure("source is required"))
  let source = match values {
    [value, ..] => value
    [] => raise Failure::Failure("source is required")
  }
  { global: matches.flags.contains(global_option), source }
}

///|
async fn run_skill_add(matches : @argparse.Matches) -> Unit {
  let options = skill_add_options(matches)
  let agents = agents_dir(options.global)
  ensure_lock(agents)
  let root = dirname(agents)
  let (source_type, source, dir) = match options.source {
    Local(path) => (RepositoryLocal, path, local_source_path(path, root))
    Github(repo) => (RepositoryGithub, repo, ensure_repo(repo))
  }
  let market = detect_marketplace(dir).unwrap_or_error(
    Failure::Failure("No supported marketplace found in \{dir}"),
  )
  let hash = match source_type {
    RepositoryGithub => Some(commit_hash(dir))
    RepositoryLocal => None
  }
  let lock = read_lock(agents)
  let skills = resolve_skills(dir, market.kind)
  let incoming_plugins = plugins_from_skills(skills)
  let mut merged = false
  for index, repo in lock.repositories {
    if repo.source == source {
      lock.repositories[index] = {
        source_type,
        source,
        marketplace_kind: market.kind,
        commit_hash: hash,
        plugins: merge_plugins(repo.plugins, incoming_plugins),
      }
      merged = true
    }
  }
  if !merged {
    lock.repositories.push({
      source_type,
      source,
      marketplace_kind: market.kind,
      commit_hash: hash,
      plugins: incoming_plugins,
    })
  }
  write_lock(agents, lock)
  sync_all(agents)
  println("Added \{source}")
}

///|
async fn run_skill_sync(matches : @argparse.Matches) -> Unit {
  let options = skill_global_options(matches)
  sync_all(agents_dir(options.global))
}

///|
async fn run_skill_update(matches : @argparse.Matches) -> Unit {
  let options = skill_global_options(matches)
  let agents = agents_dir(options.global)
  let lock = read_lock(agents)
  let updated : Array[LockRepository] = []
  for repo in lock.repositories {
    match repo.source_type {
      RepositoryGithub => {
        let dir = update_repo(repo.source)
        updated.push({
          source_type: repo.source_type,
          source: repo.source,
          marketplace_kind: repo.marketplace_kind,
          commit_hash: Some(commit_hash(dir)),
          plugins: repo.plugins,
        })
      }
      RepositoryLocal => updated.push(repo)
    }
  }
  write_lock(agents, { skill_dirs: lock.skill_dirs, repositories: updated })
  sync_all(agents)
}

///|
async fn run_skill_remove(matches : @argparse.Matches) -> Unit {
  let options = skill_remove_options(matches)
  let agents = agents_dir(options.global)
  let source = options.source
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
