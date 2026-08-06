///|
fn expect_rejection(action : () -> Unit raise, detail : String) -> Unit raise {
  try action() catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection: \{detail}")
  }
}

///|
test "GitHubRepository from_route rejects empty and malformed components" {
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/") |> ignore },
    "empty repository component",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepository::from_route("owner/repo/extra") |> ignore
    },
    "three route components",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepository::from_route("owner/repo/name") |> ignore
    },
    "path-like route",
  )
}

///|
test "GitHubRepository from_route rejects path-like repository names" {
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/.") |> ignore },
    "dot repository",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubRepository::from_route("owner/..") |> ignore },
    "dot-dot repository",
  )
}

///|
test "GitHubOwner enforces GitHub component boundaries" {
  inspect(
    GitHubOwner::GitHubOwner("a".repeat(39)).value().length(),
    content="39",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("-owner") |> ignore },
    "leading hyphen",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("owner-") |> ignore },
    "trailing hyphen",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("owner--name") |> ignore },
    "consecutive hyphens",
  )
  expect_rejection(
    fn() -> Unit raise { GitHubOwner::GitHubOwner("a".repeat(40)) |> ignore },
    "length 40",
  )
}

///|
test "GitHubRepositoryName enforces GitHub length boundary" {
  inspect(
    GitHubRepositoryName::GitHubRepositoryName("a".repeat(100)).value().length(),
    content="100",
  )
  expect_rejection(
    fn() -> Unit raise {
      GitHubRepositoryName::GitHubRepositoryName("a".repeat(101)) |> ignore
    },
    "length 101",
  )
}

///|
test "relative paths reject traversal and absolute paths" {
  expect_rejection(
    fn() -> Unit raise {
      RelativeSourcePath::RelativeSourcePath("../outside") |> ignore
    },
    "source parent traversal",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativePluginPath::RelativePluginPath("plugin/../outside") |> ignore
    },
    "plugin parent traversal",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativeSourcePath::RelativeSourcePath("/absolute/repository") |> ignore
    },
    "absolute source path",
  )
  expect_rejection(
    fn() -> Unit raise {
      RelativePluginPath::RelativePluginPath("/absolute/plugin") |> ignore
    },
    "absolute plugin path",
  )
}

///|
test "domain names reject empty and slash values" {
  expect_rejection(
    fn() -> Unit raise { PluginName::PluginName("") |> ignore },
    "empty plugin",
  )
  expect_rejection(
    fn() -> Unit raise { PluginName::PluginName("plugin/name") |> ignore },
    "path-like plugin",
  )
  expect_rejection(
    fn() -> Unit raise { SkillName::SkillName("") |> ignore },
    "empty skill",
  )
  expect_rejection(
    fn() -> Unit raise { SkillName::SkillName("skill/name") |> ignore },
    "path-like skill",
  )
}

///|
test "CommitId rejects bad length and hexadecimal boundaries" {
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("0123456789abcdef0123456789abcdef0123456") |> ignore
    },
    "39-character commit",
  )
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("0123456789abcdef0123456789abcdef012345678") |> ignore
    },
    "41-character commit",
  )
  expect_rejection(
    fn() -> Unit raise {
      CommitId::CommitId("g123456789abcdef0123456789abcdef01234567") |> ignore
    },
    "non-hexadecimal commit",
  )
}

///|
test "SkillName preserves the c-plugin skill namespace" {
  inspect(SkillName::SkillName("c-plugin").value(), content="c-plugin")
}
