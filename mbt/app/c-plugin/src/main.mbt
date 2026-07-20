///|
async fn main {
  let app = @admiral.cli(
    name="c-plugin",
    description="CLI to manage Claude Code Plugin resources",
    commands=[
      init_command_def(run_init),
      @admiral.command(
        name="skill",
        description="Manage skills from plugin repositories",
        subcommands=[
          skill_add_command_def(run_skill_add),
          skill_sync_command_def(run_skill_sync),
          skill_update_command_def(run_skill_update),
          skill_remove_command_def(run_skill_remove),
          @admiral.command(
            name="target",
            description="Manage skill symlink target directories",
            subcommands=[
              target_add_command_def(run_target_add),
              target_remove_command_def(run_target_remove),
            ],
          ),
        ],
      ),
      @admiral.command(
        name="dev",
        description="Development tools for plugin authors",
        subcommands=[
          @admiral.command(
            name="marketplace",
            description="Marketplace development tools",
            subcommands=[
              dev_marketplace_sync_command_def(run_dev_marketplace_sync),
            ],
          ),
        ],
      ),
    ],
  )
  app.run()
}
