///|
async fn main {
  let greet_name = @admiral.string(
    "name",
    short='n',
    description="Name to greet",
    env="ADMIRAL_NAME",
    required=true,
  )
  let greet_loud = @admiral.bool(
    "loud",
    short='l',
    description="Shout the greeting",
  )
  let greet_count = @admiral.int(
    "count",
    short='c',
    description="Repeat count",
    default=Some(1),
  )
  let migrate_dry_run = @admiral.bool(
    "dry-run",
    description="Preview without applying",
  )
  let migrate_up_steps = @admiral.int(
    "steps",
    short='s',
    description="Number of migrations to apply",
  )
  let migrate_down_steps = @admiral.int(
    "steps",
    short='s',
    description="Number of migrations to rollback",
    default=Some(1),
  )
  let seed_file = @admiral.string(
    "file",
    short='f',
    description="Seed file path",
    default=Some("seeds/default.sql"),
  )
  let inspect_value = @admiral.position_int("value", required=true)
  let inspect_labels = @admiral.position_strings("labels")
  let app = @admiral.cli(
    name="myapp",
    version="0.1.0",
    description="Example CLI with nested subcommands",
    commands=[
      @admiral.command(
        name="greet",
        description="Greet someone",
        options=[greet_name, greet_loud, greet_count],
        examples=[
          "myapp greet --name Alice", "myapp greet --name Bob --loud --count 3",
        ],
        run=Some(async fn(ctx) {
          @async.sleep(0)
          let name = ctx.get_string_required(greet_name) catch { _ => return }
          let loud = ctx.get_bool(greet_loud)
          let count = match ctx.get_int(greet_count) {
            Some(n) => n
            None => 1
          }
          for i = 0; i < count; i = i + 1 {
            let msg = "Hello, " + name + "!"
            if loud {
              println(msg.to_upper())
            } else {
              println(msg)
            }
          }
        }),
      ),
      @admiral.command(name="db", description="Database commands", subcommands=[
        @admiral.command(
          name="migrate",
          description="Run database migrations",
          subcommands=[
            @admiral.command(
              name="up",
              description="Apply pending migrations",
              options=[migrate_dry_run, migrate_up_steps],
              examples=[
                "myapp db migrate up", "myapp db migrate up --dry-run", "myapp db migrate up --steps 5",
              ],
              run=Some(async fn(ctx) {
                @async.sleep(0)
                let dry = ctx.get_bool(migrate_dry_run)
                let steps = ctx.get_int(migrate_up_steps)
                if dry {
                  println("[DRY RUN] Would apply migrations")
                } else {
                  match steps {
                    Some(n) =>
                      println("Applying " + n.to_string() + " migrations...")
                    None => println("Applying all pending migrations...")
                  }
                }
                println("Done.")
              }),
            ),
            @admiral.command(
              name="down",
              description="Rollback migrations",
              options=[migrate_down_steps],
              run=Some(async fn(ctx) {
                @async.sleep(0)
                let steps = match ctx.get_int(migrate_down_steps) {
                  Some(n) => n
                  None => 1
                }
                println(
                  "Rolling back " + steps.to_string() + " migration(s)...",
                )
                println("Done.")
              }),
            ),
          ],
        ),
        @admiral.command(
          name="seed",
          description="Seed the database",
          options=[seed_file],
          run=Some(async fn(ctx) {
            @async.sleep(0)
            let file = match ctx.get_string(seed_file) {
              Some(f) => f
              None => "seeds/default.sql"
            }
            println("Seeding from: " + file)
          }),
        ),
      ]),
      @admiral.command(
        name="inspect",
        description="Inspect typed positional values",
        positionals=[inspect_value, inspect_labels],
        run=Some(async fn(ctx) {
          @async.sleep(0)
          let value = ctx.get_int_required(inspect_value) catch { _ => return }
          let labels = ctx.get_strings(inspect_labels).unwrap_or([])
          println("value=" + value.to_string())
          println("labels=" + labels.join(","))
        }),
      ),
    ],
  )
  // --schema flag: output structured JSON and exit
  let args = @env.args()
  if args.length() > 0 && args[args.length() - 1] == "--schema" {
    println(app.render_schema())
    return
  }
  app.run()
}
