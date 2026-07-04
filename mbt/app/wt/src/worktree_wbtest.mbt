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
