///|
test "parse_github_remote matches JS owner repo parsing" {
  inspect(
    parse_github_remote("https://github.com/owner/repo.git").unwrap_or(""),
    content="owner/repo",
  )
  inspect(
    parse_github_remote("https://github.com/owner/repo").unwrap_or(""),
    content="owner/repo",
  )
  inspect(
    parse_github_remote("git@github.com:owner/repo.git").unwrap_or(""),
    content="owner/repo",
  )
  inspect(
    parse_github_remote("https://example.com/owner/repo.git").unwrap_or(""),
    content="",
  )
}

///|
test "parse_worktree_list uses repo path for main detection and preserves detached entries" {
  let output = "worktree /repo/feature\nHEAD abc\nbranch refs/heads/feature\n\nworktree /repo/main\nHEAD def\nbranch refs/heads/main\n\nworktree /repo/detached\nHEAD ghi\ndetached\n"
  let entries = parse_worktree_list(output, "/repo/main")
  inspect(entries.length(), content="3")
  inspect(entries[0].path, content="/repo/feature")
  inspect(entries[0].branch.unwrap_or(""), content="feature")
  inspect(entries[0].is_main, content="false")
  inspect(entries[1].path, content="/repo/main")
  inspect(entries[1].branch.unwrap_or(""), content="main")
  inspect(entries[1].is_main, content="true")
  inspect(entries[2].path, content="/repo/detached")
  inspect(entries[2].branch.unwrap_or(""), content="")
}

///|
test "parse_worktree_list ignores blocks without worktree line" {
  let entries = parse_worktree_list(
    "HEAD abc\nbranch refs/heads/main\n", "/repo",
  )
  inspect(entries.length(), content="0")
}

///|
async test "fetch_repo_worktrees resolves a nested repository path" {
  let root = @fs.tmpdir(prefix="wt-fetch-repo-worktrees-")
  let nested = "\{root}/some/nested/directory"
  @fs.mkdir(nested, recursive=true)
  run_checked("git", ["init", root])
  run_checked("git", [
    "-C", root, "config", "remote.origin.url", "https://github.com/owner/repo.git",
  ])
  match fetch_repo_worktrees(nested) {
    Some(result) => {
      inspect(basename(result.repo_path), content=basename(root))
      inspect(result.slug, content="owner/repo")
      inspect(result.entries.length(), content="1")
    }
    None => inspect(false, content="true")
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_worktree_statuses - starts all fetches before awaiting results" {
  let started = Ref(0)
  let second_finished = Ref(false)
  let entry_array = [
    { path: "/repo/first", branch: Some("first"), is_main: false },
    { path: "/repo/second", branch: Some("second"), is_main: false },
  ]
  async fn fetch(entry : WorktreeEntry) -> WorktreeStatus? {
    started.val = started.val + 1
    while started.val < entry_array.length() {
      @async.pause()
    }
    if entry.path == "/repo/first" {
      while !second_finished.val {
        @async.pause()
      }
    } else {
      second_finished.val = true
    }
    Some(
      WorktreeStatus(
        entry~,
        branch=entry.branch.unwrap_or(""),
        pr={ state: "none", number: None },
        git="committed",
      ),
    )
  }

  let result = @async.with_timeout_opt(1000, () => {
    collect_worktree_statuses(entry_array, fetch)
  })
  guard result is Some(status_array)
  assert_true(started.val == entry_array.length())
  assert_true(status_array[0].entry.path == "/repo/first")
  assert_true(status_array[1].entry.path == "/repo/second")
}

///|
test "format_pr matches original JS output" {
  inspect(format_pr({ state: "main", number: None }), content="main")
  inspect(format_pr({ state: "none", number: None }), content="none")
  inspect(
    format_pr({ state: "merged", number: Some("123") }),
    content="MERGED(#123)",
  )
  inspect(
    format_pr({ state: "open", number: Some("123") }),
    content="OPEN(#123)",
  )
  inspect(
    format_pr({ state: "closed", number: Some("123") }),
    content="CLOSED(#123)",
  )
  inspect(format_pr({ state: "merged", number: None }), content="MERGED(#?)")
}
