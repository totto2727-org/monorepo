///|
test "render_schema outputs JSON for simple command" {
  let app = cli(name="myapp", version="1.0.0", description="Test app", commands=[
    command(name="greet", description="Greet someone", options=[
      string("name", short='n', description="Name to greet", required=true),
      bool("verbose", short='v', description="Verbose output"),
      int("count", description="Repeat count", default=Some(3)),
      int64("offset"),
      uint("retries"),
      uint64("limit"),
      double("ratio"),
    ]),
  ])
  let schema = app.render_schema()
  // Verify key parts exist in JSON output
  inspect(schema.contains("\"name\":\"myapp\""), content="true")
  inspect(schema.contains("\"version\":\"1.0.0\""), content="true")
  inspect(schema.contains("\"description\":\"Test app\""), content="true")
  inspect(schema.contains("\"greet\""), content="true")
  inspect(schema.contains("\"type\":\"string\""), content="true")
  inspect(schema.contains("\"required\":true"), content="true")
  inspect(schema.contains("\"type\":\"bool\""), content="true")
  inspect(schema.contains("\"style\":\"flag\""), content="true")
  inspect(schema.contains("\"type\":\"int\""), content="true")
  inspect(schema.contains("\"type\":\"int64\""), content="true")
  inspect(schema.contains("\"type\":\"uint\""), content="true")
  inspect(schema.contains("\"type\":\"uint64\""), content="true")
  inspect(schema.contains("\"type\":\"double\""), content="true")
  inspect(schema.contains("\"default\":\"3\""), content="true")
  inspect(schema.contains("\"short\":\"n\""), content="true")
}

///|
test "render_schema outputs nested subcommands" {
  let app = cli(name="db-tool", version="0.1.0", description="DB tool", commands=[
    command(name="db", description="Database commands", subcommands=[
      command(name="migrate", description="Migrations", subcommands=[
        command(name="up", description="Apply migrations", options=[
          bool("dry-run", description="Dry run"),
        ]),
      ]),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"db\""), content="true")
  inspect(schema.contains("\"migrate\""), content="true")
  inspect(schema.contains("\"up\""), content="true")
  inspect(schema.contains("\"dry-run\""), content="true")
  inspect(schema.contains("\"Dry run\""), content="true")
}

///|
test "render_schema auto-generates examples when not provided" {
  let app = cli(name="myapp", version="0.1.0", description="Test", commands=[
    command(
      name="greet",
      description="Greet someone",
      options=[
        string("name", short='n', description="Name", required=true),
        bool("loud", short='l', description="Loud"),
        int("count", short='c', description="Count", default=Some(1)),
      ],
      // no examples provided
    ),
  ])
  let schema = app.render_schema()
  // Should auto-generate an example
  inspect(schema.contains("\"examples\""), content="true")
  inspect(schema.contains("myapp greet --name"), content="true")
}

///|
test "render_schema does not override provided examples" {
  let app = cli(name="myapp", version="0.1.0", description="Test", commands=[
    command(
      name="greet",
      description="Greet someone",
      options=[string("name", description="Name", required=true)],
      examples=["myapp greet --name Alice"],
    ),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("myapp greet --name Alice"), content="true")
}

///|
test "render_schema auto-generates examples for nested commands" {
  let app = cli(name="myapp", version="0.1.0", description="Test", commands=[
    command(name="db", description="DB", subcommands=[
      command(
        name="migrate",
        description="Migrate",
        options=[bool("dry-run", description="Dry")],
        // no examples
      ),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("myapp db migrate"), content="true")
}

///|
test "render_schema_json returns Json value" {
  let app = cli(name="test", version="0.1.0", description="Test", commands=[
    command(name="hello", description="Say hello", options=[
      string("name", description="Name", required=true),
    ]),
  ])
  let json = app.render_schema_json()
  // Json can be converted back to string
  let s = json.stringify()
  inspect(s.contains("\"hello\""), content="true")
  inspect(s.contains("\"name\""), content="true")
}

///|
test "render_schema includes configured environment variable name" {
  let app = cli(name="test", commands=[
    command(name="hello", options=[string("name", env="ADMIRAL_SCHEMA_NAME")]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"env\":\"ADMIRAL_SCHEMA_NAME\""), content="true")
}

///|
test "render_schema omits env for unconfigured options" {
  let app = cli(name="test", commands=[
    command(name="hello", options=[string("name")]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"env\""), content="false")
}

///|
test "render_schema includes config keys for options and positions" {
  let app = cli(name="test", commands=[
    command(name="run", options=[string("name", config="name")], positionals=[
      position_string("input", config="input"),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"config\":\"name\""), content="true")
  inspect(schema.contains("\"config\":\"input\""), content="true")
}

///|
test "render_schema does not expose resolved environment values" {
  let key = "ADMIRAL_SCHEMA_NAME"
  let sentinel = "SCHEMA_FAKE_RESOLVED_VALUE_7C9F"
  let previous = @env.get_env_var(key)
  @env.set_env_var(key, sentinel)
  let app = cli(name="test", commands=[
    command(name="hello", options=[string("name", env=key)]),
  ])
  let schema = app.render_schema()
  match previous {
    Some(value) => @env.set_env_var(key, value)
    None => @env.unset_env_var(key)
  }
  inspect(schema.contains("\"env\":\"ADMIRAL_SCHEMA_NAME\""), content="true")
  inspect(schema.contains(sentinel), content="false")
}
