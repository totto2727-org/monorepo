///|
struct Project {
  name : String
  description : String
}

///|
let projects : Array[Project] = [
  { name: "admiral", description: "Declarative CLI builder" },
  { name: "codex-sdk", description: "Codex SDK for MoonBit" },
  { name: "lens", description: "Typed JSON lenses" },
  { name: "moon-agent-graph", description: "Agent workflow runtime" },
  { name: "opencode-sdk", description: "OpenCode SDK for MoonBit" },
]

///|
fn search_projects(query : String) -> Array[Project] {
  let normalized = query.to_lower()
  if normalized.length() == 0 {
    return projects.copy()
  }
  projects
  .iter()
  .filter(project => {
    project.name.to_lower().contains(normalized) ||
    project.description.to_lower().contains(normalized)
  })
  .collect()
}

///|
fn drop_last_character(value : String) -> String {
  let characters : Array[Char] = value.iter().collect()
  if characters.length() == 0 {
    return value
  }
  characters
  .iter()
  .take(characters.length() - 1)
  .map(character => character.to_string())
  .collect()
  .join("")
}

///|
fn select_project(initial_project : String?, initial_query : String) -> String? {
  let query = Ref(
    if initial_query.length() > 0 {
      initial_query
    } else {
      initial_project.unwrap_or("")
    },
  )
  let selected_index = Ref(0)
  let result : Ref[String?] = Ref(None)

  fn filtered_projects() -> Array[Project] {
    search_projects(query.val)
  }

  fn reset_selection() -> Unit {
    selected_index.val = 0
  }

  fn render() {
    let matches = filtered_projects()
    let rows = []
    for index, project in matches {
      let selected = index == selected_index.val
      rows.push(
        @tui.text(
          (if selected { "> " } else { "  " }) +
          project.name +
          "  " +
          project.description,
          fg=if selected { "cyan" } else { "white" },
          bold=selected,
        ),
      )
    }
    if rows.length() == 0 {
      rows.push(@tui.text("  No matching projects", fg="yellow"))
    }
    @tui.column(
      padding=1.0,
      gap=1.0,
      border="rounded",
      border_color="cyan",
      [
        @tui.text("Select a project", fg="cyan", bold=true),
        @tui.text("Search: " + query.val + "_", fg="yellow"),
      ] +
      rows +
      [@tui.text("Type to search | ↑↓ move | Enter select | Esc cancel")],
    )
  }

  fn handle_event(event : @tui.InputEvent) -> Bool {
    match event {
      @tui.InputEvent::Key(key) =>
        match key {
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _)
          | @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => false
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => {
            let matches = filtered_projects()
            if matches.length() > 0 {
              result.val = Some(matches[selected_index.val].name)
            }
            false
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            if selected_index.val > 0 {
              selected_index.val = selected_index.val - 1
            }
            true
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            let matches = filtered_projects()
            if selected_index.val + 1 < matches.length() {
              selected_index.val = selected_index.val + 1
            }
            true
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
            query.val = drop_last_character(query.val)
            reset_selection()
            true
          }
          @tui.KeyEvent::Char(character, @tui.KeyModifier::None)
          | @tui.KeyEvent::Char(character, @tui.KeyModifier::Shift) => {
            query.val = query.val + character.to_string()
            reset_selection()
            true
          }
          _ => true
        }
      _ => true
    }
  }

  let (width, height) = @tui.get_terminal_size()
  let app = @tui.VNodeApp::new(width, height)
  fn render_frame() -> Unit {
    @tui.print_raw(app.render_frame(render()))
  }
  fn handle_key(value : String) -> Unit {
    if value.length() == 0 {
      return
    }
    if handle_event(@tui.parse_input(value)) {
      render_frame()
    } else {
      @tui.stop_keypress_listener()
      @tui.print_raw(@tui.VNodeApp::restore_terminal())
    }
  }
  @tui.print_raw(@tui.VNodeApp::init_terminal())
  render_frame()
  @tui.start_keypress_listener(handle_key)
  result.val
}

///|
async fn main {
  let project = @admiral.position_string(
    "project",
    description="Project selected by name",
    required=true,
    interactive=true,
  )
  let query = @admiral.string(
    "query",
    short='q',
    description="Initial project search",
    env="ADMIRAL_PROJECT_QUERY",
    default=Some(""),
    interactive=true,
  )
  let app = @admiral.cli(
    name="interactive-project",
    version="0.1.0",
    description="Admiral interactive project search example",
    positionals=[project],
    options=[query],
    interactive=Some(input => {
      let initial = input.to_context()
      match
        select_project(
          initial.get_string(project),
          initial.get_string(query).unwrap_or(""),
        ) {
        Some(selected) => input.set_string(project, selected)
        None => fail("project selection cancelled")
      }
    }),
    run=Some(ctx => {
      let selected = ctx.get_string_required(project)
      println("Selected project: " + selected)
    }),
  )
  app.run()
}
