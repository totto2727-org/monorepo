// MoonBit FromJson implementations for wire formats that cannot use derive(FromJson).
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L103
// Item shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L5-L128

///|
let item_id_lens : @lens.Lens[Json] = @lens.root().json("id")

///|
let command_execution_command_lens : @lens.Lens[Json] = @lens.root().json(
  "command",
)

///|
let command_execution_aggregated_output_lens : @lens.Lens[Json] = @lens.root().json(
  "aggregated_output",
)

///|
let command_execution_exit_code_lens : @lens.Lens[Json?] = @lens.root()
  .json("exit_code")
  .nullish()

///|
let item_status_lens : @lens.Lens[Json] = @lens.root().json("status")

///|
let file_update_path_lens : @lens.Lens[Json] = @lens.root().json("path")

///|
let file_update_kind_lens : @lens.Lens[Json] = @lens.root().json("kind")

///|
let mcp_result_content_lens : @lens.Lens[Json] = @lens.root().json("content")

///|
let mcp_result_meta_lens : @lens.Lens[Json?] = @lens.root()
  .json("_meta")
  .nullish()

///|
let mcp_result_structured_content_lens : @lens.Lens[Json] = @lens.root().json(
  "structured_content",
)

///|
let mcp_item_server_lens : @lens.Lens[Json] = @lens.root().json("server")

///|
let mcp_item_tool_lens : @lens.Lens[Json] = @lens.root().json("tool")

///|
let mcp_item_arguments_lens : @lens.Lens[Json] = @lens.root().json("arguments")

///|
let mcp_item_result_lens : @lens.Lens[Json?] = @lens.root()
  .json("result")
  .nullish()

///|
let mcp_item_error_lens : @lens.Lens[Json?] = @lens.root()
  .json("error")
  .nullish()

///|
let file_change_changes_lens : @lens.Lens[Json] = @lens.root().json("changes")

///|
let todo_list_items_lens : @lens.Lens[Json] = @lens.root().json("items")

///|
let thread_item_type_lens : @lens.Lens[Json] = @lens.root().json("type")

///|
pub impl @json.FromJson for CommandExecutionStatus with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "in_progress" => InProgress
    "completed" => Completed
    "failed" => Failed
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported command execution status: \{value}"),
      )
  }
}

///|
pub impl @json.FromJson for PatchChangeKind with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "add" => Add
    "delete" => Delete
    "update" => Update
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported patch change kind: \{value}"),
      )
  }
}

///|
pub impl @json.FromJson for PatchApplyStatus with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "completed" => PatchCompleted
    "failed" => PatchFailed
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported patch apply status: \{value}"),
      )
  }
}

///|
pub impl @json.FromJson for McpToolCallStatus with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "in_progress" => McpInProgress
    "completed" => McpCompleted
    "failed" => McpFailed
    _ =>
      raise @json.JsonDecodeError(
        (path, "unsupported MCP tool call status: \{value}"),
      )
  }
}

///|
pub impl @json.FromJson for CommandExecutionItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "command_execution must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("id"), "command_execution is missing id"),
        )
    },
    path=path.add_key("id"),
  )
  let command : String = @json.from_json(
    command_execution_command_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("command"), "command_execution is missing command"),
        )
    },
    path=path.add_key("command"),
  )
  let aggregated_output : String = @json.from_json(
    command_execution_aggregated_output_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (
            path.add_key("aggregated_output"),
            "command_execution is missing aggregated_output",
          ),
        )
    },
    path=path.add_key("aggregated_output"),
  )
  let exit_code_value = command_execution_exit_code_lens.get(json) catch {
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("exit_code"), "command_execution is missing exit_code"),
      )
  }
  let exit_code = match exit_code_value {
    Some(value) => Some(@json.from_json(value, path=path.add_key("exit_code")))
    None => None
  }
  let status : CommandExecutionStatus = @json.from_json(
    item_status_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("status"), "command_execution is missing status"),
        )
    },
    path=path.add_key("status"),
  )
  { id, command, aggregated_output, exit_code, status }
}

///|
pub impl @json.FromJson for FileUpdateChange with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "file update must be an object"))
  }
  let path_value : String = @json.from_json(
    file_update_path_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("path"), "file update is missing path"),
        )
    },
    path=path.add_key("path"),
  )
  let kind : PatchChangeKind = @json.from_json(
    file_update_kind_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("kind"), "file update is missing kind"),
        )
    },
    path=path.add_key("kind"),
  )
  { path: @path.Path(path_value), kind }
}

///|
pub impl @json.FromJson for McpToolCallResult with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "MCP tool result must be an object"))
  }
  let content : Array[Json] = @json.from_json(
    mcp_result_content_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("content"), "MCP tool result is missing content"),
        )
    },
    path=path.add_key("content"),
  )
  let meta = mcp_result_meta_lens.get(json) catch { _ => None }
  let structured_content : Json = @json.from_json(
    mcp_result_structured_content_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (
            path.add_key("structured_content"),
            "MCP tool result is missing structured_content",
          ),
        )
    },
    path=path.add_key("structured_content"),
  )
  { content: ReadOnlyArray::from_array(content), meta, structured_content }
}

///|
pub impl @json.FromJson for McpToolCallItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "mcp_tool_call must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("id"), "mcp_tool_call is missing id"),
        )
    },
    path=path.add_key("id"),
  )
  let server : String = @json.from_json(
    mcp_item_server_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("server"), "mcp_tool_call is missing server"),
        )
    },
    path=path.add_key("server"),
  )
  let tool : String = @json.from_json(
    mcp_item_tool_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("tool"), "mcp_tool_call is missing tool"),
        )
    },
    path=path.add_key("tool"),
  )
  let arguments : Json = @json.from_json(
    mcp_item_arguments_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("arguments"), "mcp_tool_call is missing arguments"),
        )
    },
    path=path.add_key("arguments"),
  )
  let result_value = mcp_item_result_lens.get(json) catch { _ => None }
  let result = match result_value {
    Some(value) => Some(@json.from_json(value, path=path.add_key("result")))
    None => None
  }
  let error_value = mcp_item_error_lens.get(json) catch { _ => None }
  let error = match error_value {
    Some(value) => Some(@json.from_json(value, path=path.add_key("error")))
    None => None
  }
  let status : McpToolCallStatus = @json.from_json(
    item_status_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("status"), "mcp_tool_call is missing status"),
        )
    },
    path=path.add_key("status"),
  )
  { id, server, tool, arguments, result, error, status }
}

///|
pub impl @json.FromJson for FileChangeItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "file_change must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("id"), "file_change is missing id"),
        )
    },
    path=path.add_key("id"),
  )
  let changes : Array[FileUpdateChange] = @json.from_json(
    file_change_changes_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("changes"), "file_change is missing changes"),
        )
    },
    path=path.add_key("changes"),
  )
  let status : PatchApplyStatus = @json.from_json(
    item_status_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("status"), "file_change is missing status"),
        )
    },
    path=path.add_key("status"),
  )
  { id, changes: ReadOnlyArray::from_array(changes), status }
}

///|
pub impl @json.FromJson for TodoListItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "todo_list must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("id"), "todo_list is missing id"),
        )
    },
    path=path.add_key("id"),
  )
  let items : Array[TodoItem] = @json.from_json(
    todo_list_items_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("items"), "todo_list is missing items"),
        )
    },
    path=path.add_key("items"),
  )
  { id, items: ReadOnlyArray::from_array(items) }
}

///|
pub impl @json.FromJson for ThreadItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "thread item must be an object"))
  }
  let item_type : String = @json.from_json(
    thread_item_type_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("type"), "thread item is missing type"),
        )
    },
    path=path.add_key("type"),
  )
  match item_type {
    "agent_message" => AgentMessage(@json.from_json(json, path~))
    "reasoning" => Reasoning(@json.from_json(json, path~))
    "command_execution" => CommandExecution(@json.from_json(json, path~))
    "file_change" => FileChange(@json.from_json(json, path~))
    "mcp_tool_call" => McpToolCall(@json.from_json(json, path~))
    "web_search" => WebSearch(@json.from_json(json, path~))
    "todo_list" => TodoList(@json.from_json(json, path~))
    "error" => Error(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "unsupported thread item type: \{item_type}"),
      )
  }
}
