///|
async fn main {
  @async.with_task_group(group => {
    let mut help_path : Array[String]? = None
    let app = @admiral.cli(
      name="c-plugin",
      description="CLI to manage Claude Code Plugin resources",
      commands=[
        init_command_def(context => group.spawn_bg(() => run_init(context))),
        @admiral.command(
          name="skill",
          description="Manage skills from plugin repositories",
          subcommands=[
            skill_add_command_def(context => {
              group.spawn_bg(() => run_skill_add(context))
            }),
            skill_sync_command_def(context => {
              group.spawn_bg(() => run_skill_sync(context))
            }),
            skill_update_command_def(context => {
              group.spawn_bg(() => run_skill_update(context))
            }),
            skill_remove_command_def(context => {
              group.spawn_bg(() => run_skill_remove(context))
            }),
            @admiral.command(
              name="target",
              description="Manage skill symlink target directories",
              subcommands=[
                target_add_command_def(context => {
                  group.spawn_bg(() => run_target_add(context))
                }),
                target_remove_command_def(context => {
                  group.spawn_bg(() => run_target_remove(context))
                }),
              ],
              run=Some(_ => help_path = Some(["skill", "target"])),
            ),
          ],
          run=Some(_ => help_path = Some(["skill"])),
        ),
        @admiral.command(
          name="dev",
          description="Development tools for plugin authors",
          subcommands=[
            @admiral.command(
              name="marketplace",
              description="Marketplace development tools",
              subcommands=[
                dev_marketplace_sync_command_def(context => {
                  group.spawn_bg(() => run_dev_marketplace_sync(context))
                }),
              ],
              run=Some(_ => help_path = Some(["dev", "marketplace"])),
            ),
          ],
          run=Some(_ => help_path = Some(["dev"])),
        ),
      ],
    )
    if @env.args().length() <= 1 {
      app.run(argv=Some(["-h"]))
      return
    }
    app.run()
    if help_path is Some(path) {
      app.run(argv=Some(path + ["-h"]))
    }
  })
}
