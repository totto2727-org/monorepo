///|
async test "resolve_skills reads Codex source.path marketplace entries" {
  let root = @fs.tmpdir(prefix="c-plugin-codex-")
  let repo = @path.Path::join(root, "repo").to_string()
  @test_support.write_codex_marketplace(repo)
  @test_support.write_skill(repo, "codex-skill")
  let skills = resolve_skills(repo, Codex)
  inspect(skills.length(), content="1")
  inspect(skills[0].plugin_path, content="plugins/plugin-a")
  inspect(skills[0].skill_name, content="codex-skill")
  @fs.rmdir(root, recursive=true)
}

///|
async test "resolve_skills resolves multiple plugins and excludes directories without SKILL.md" {
  let root = @fs.tmpdir(prefix="c-plugin-resolve-multiple-")
  let repo = @path.Path::join(root, "repo").to_string()
  @test_support.write_text(
    (repo
    |> @path.Path::join(".claude-plugin")
    |> @path.Path::join("marketplace.json")).to_string(),
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "plugin-a", "source": "plugins/plugin-a" },
      #|    { "name": "plugin-b", "source": "plugins/plugin-b" }
      #|  ]
      #|}
    ),
  )
  @test_support.write_text(
    (repo
    |> @path.Path::join("plugins")
    |> @path.Path::join("plugin-a")
    |> @path.Path::join("skills")
    |> @path.Path::join("skill-1")
    |> @path.Path::join("SKILL.md")).to_string(),
    "# skill-1\n",
  )
  @test_support.write_text(
    (repo
    |> @path.Path::join("plugins")
    |> @path.Path::join("plugin-b")
    |> @path.Path::join("skills")
    |> @path.Path::join("skill-2")
    |> @path.Path::join("SKILL.md")).to_string(),
    "# skill-2\n",
  )
  @fs.mkdir(
    (repo
    |> @path.Path::join("plugins")
    |> @path.Path::join("plugin-b")
    |> @path.Path::join("skills")
    |> @path.Path::join("no-skill-md")).to_string(),
    recursive=true,
  )
  let skills = resolve_skills(repo, Claude)
  inspect(skills.length(), content="2")
  inspect(
    skills.map(fn(skill) { skill.skill_name }).join(","),
    content="skill-1,skill-2",
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "resolve_skills returns empty when plugin has no skills directory" {
  let root = @fs.tmpdir(prefix="c-plugin-resolve-empty-")
  let repo = @path.Path::join(root, "repo").to_string()
  @test_support.write_text(
    (repo
    |> @path.Path::join(".claude-plugin")
    |> @path.Path::join("marketplace.json")).to_string(),
    (
      #|{
      #|  "name": "test-marketplace",
      #|  "plugins": [
      #|    { "name": "empty-plugin", "source": "plugins/empty-plugin" }
      #|  ]
      #|}
    ),
  )
  let skills = resolve_skills(repo, Claude)
  inspect(skills.length(), content="0")
  @fs.rmdir(root, recursive=true)
}

///|
test "plugins_from_skills groups enabled skills by plugin without duplicates" {
  let plugins = plugins_from_skills([
    {
      plugin_name: "plugin-a",
      plugin_path: "plugins/plugin-a",
      skill_name: "skill-1",
      skill_path: "/repo/plugins/plugin-a/skills/skill-1",
    },
    {
      plugin_name: "plugin-a",
      plugin_path: "plugins/plugin-a",
      skill_name: "skill-2",
      skill_path: "/repo/plugins/plugin-a/skills/skill-2",
    },
    {
      plugin_name: "plugin-a",
      plugin_path: "plugins/plugin-a",
      skill_name: "skill-1",
      skill_path: "/repo/plugins/plugin-a/skills/skill-1",
    },
  ])
  inspect(plugins.length(), content="1")
  inspect(plugins[0].name, content="plugin-a")
  inspect(plugins[0].path, content="plugins/plugin-a")
  inspect(plugins[0].enabled_skills.join(","), content="skill-1,skill-2")
}

///|
test "merge_plugins preserves existing plugin and appends new enabled skills" {
  let merged = merge_plugins(
    [
      {
        name: "plugin-a",
        path: "plugins/plugin-a",
        enabled_skills: ["skill-1"],
      },
    ],
    [
      {
        name: "plugin-a",
        path: "plugins/plugin-a",
        enabled_skills: ["skill-1", "skill-2"],
      },
      {
        name: "plugin-b",
        path: "plugins/plugin-b",
        enabled_skills: ["skill-3"],
      },
    ],
  )
  inspect(merged.length(), content="2")
  inspect(merged[0].enabled_skills.join(","), content="skill-1,skill-2")
  inspect(merged[1].name, content="plugin-b")
  inspect(merged[1].enabled_skills.join(","), content="skill-3")
}

///|
async test "has_supported_plugin_format detects supported config directories" {
  let root = @fs.tmpdir(prefix="c-plugin-format-")
  @async
  .all(
    marketplace_kinds().map(kind => () => {
      let dir = @path.Path::join(
        root,
        marketplace_kind_to_string(kind),
      ).to_string()
      @fs.mkdir(
        @path.Path::join(dir, marketplace_config_dir(kind)).to_string(),
        recursive=true,
      )
      assert_true(has_supported_plugin_format(dir))
    }),
  )
  |> ignore
  assert_false(
    has_supported_plugin_format(@path.Path::join(root, "empty").to_string()),
  )
  assert_false(
    has_supported_plugin_format(@path.Path::join(root, "missing").to_string()),
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "detect_marketplace preserves marketplace priority" {
  let root = @fs.tmpdir(prefix="c-plugin-marketplace-priority-")
  @async
  .all(
    marketplace_kinds().map(kind => () => {
      @test_support.write_text(
        @path.Path::join(root, marketplace_path(kind)).to_string(),
        "{}\n",
      )
    }),
  )
  |> ignore
  let info = detect_marketplace(root)
  guard info is Some(info)
  assert_true(info.kind == Claude)
  @fs.rmdir(root, recursive=true)
}
