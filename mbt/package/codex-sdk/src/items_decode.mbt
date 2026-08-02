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
    item_id_lens.get_or_json_decode_error(json, path),
    path=item_id_lens.add_to_json_path(path),
  )
  let command : String = @json.from_json(
    command_execution_command_lens.get_or_json_decode_error(json, path),
    path=command_execution_command_lens.add_to_json_path(path),
  )
  let aggregated_output : String = @json.from_json(
    command_execution_aggregated_output_lens.get_or_json_decode_error(
      json, path,
    ),
    path=command_execution_aggregated_output_lens.add_to_json_path(path),
  )
  let exit_code_value = command_execution_exit_code_lens.get_or_json_decode_error(
    json, path,
  )
  let exit_code = match exit_code_value {
    Some(value) =>
      Some(
        @json.from_json(
          value,
          path=command_execution_exit_code_lens.add_to_json_path(path),
        ),
      )
    None => None
  }
  let status : CommandExecutionStatus = @json.from_json(
    item_status_lens.get_or_json_decode_error(json, path),
    path=item_status_lens.add_to_json_path(path),
  )
  { id, command, aggregated_output, exit_code, status }
}

///|
pub impl @json.FromJson for FileUpdateChange with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "file update must be an object"))
  }
  let path_value : String = @json.from_json(
    file_update_path_lens.get_or_json_decode_error(json, path),
    path=file_update_path_lens.add_to_json_path(path),
  )
  let kind : PatchChangeKind = @json.from_json(
    file_update_kind_lens.get_or_json_decode_error(json, path),
    path=file_update_kind_lens.add_to_json_path(path),
  )
  { path: @path.Path(path_value), kind }
}

///|
pub impl @json.FromJson for McpToolCallResult with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "MCP tool result must be an object"))
  }
  let content : Array[Json] = @json.from_json(
    mcp_result_content_lens.get_or_json_decode_error(json, path),
    path=mcp_result_content_lens.add_to_json_path(path),
  )
  let meta = mcp_result_meta_lens.get_or_json_decode_error(json, path)
  let structured_content : Json = @json.from_json(
    mcp_result_structured_content_lens.get_or_json_decode_error(json, path),
    path=mcp_result_structured_content_lens.add_to_json_path(path),
  )
  { content: ReadOnlyArray::from_array(content), meta, structured_content }
}

///|
pub impl @json.FromJson for McpToolCallItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "mcp_tool_call must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get_or_json_decode_error(json, path),
    path=item_id_lens.add_to_json_path(path),
  )
  let server : String = @json.from_json(
    mcp_item_server_lens.get_or_json_decode_error(json, path),
    path=mcp_item_server_lens.add_to_json_path(path),
  )
  let tool : String = @json.from_json(
    mcp_item_tool_lens.get_or_json_decode_error(json, path),
    path=mcp_item_tool_lens.add_to_json_path(path),
  )
  let arguments : Json = @json.from_json(
    mcp_item_arguments_lens.get_or_json_decode_error(json, path),
    path=mcp_item_arguments_lens.add_to_json_path(path),
  )
  let result_value = mcp_item_result_lens.get_or_json_decode_error(json, path)
  let result = match result_value {
    Some(value) =>
      Some(
        @json.from_json(value, path=mcp_item_result_lens.add_to_json_path(path)),
      )
    None => None
  }
  let error_value = mcp_item_error_lens.get_or_json_decode_error(json, path)
  let error = match error_value {
    Some(value) =>
      Some(
        @json.from_json(value, path=mcp_item_error_lens.add_to_json_path(path)),
      )
    None => None
  }
  let status : McpToolCallStatus = @json.from_json(
    item_status_lens.get_or_json_decode_error(json, path),
    path=item_status_lens.add_to_json_path(path),
  )
  { id, server, tool, arguments, result, error, status }
}

///|
pub impl @json.FromJson for FileChangeItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "file_change must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get_or_json_decode_error(json, path),
    path=item_id_lens.add_to_json_path(path),
  )
  let changes : Array[FileUpdateChange] = @json.from_json(
    file_change_changes_lens.get_or_json_decode_error(json, path),
    path=file_change_changes_lens.add_to_json_path(path),
  )
  let status : PatchApplyStatus = @json.from_json(
    item_status_lens.get_or_json_decode_error(json, path),
    path=item_status_lens.add_to_json_path(path),
  )
  { id, changes: ReadOnlyArray::from_array(changes), status }
}

///|
pub impl @json.FromJson for TodoListItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "todo_list must be an object"))
  }
  let id : String = @json.from_json(
    item_id_lens.get_or_json_decode_error(json, path),
    path=item_id_lens.add_to_json_path(path),
  )
  let items : Array[TodoItem] = @json.from_json(
    todo_list_items_lens.get_or_json_decode_error(json, path),
    path=todo_list_items_lens.add_to_json_path(path),
  )
  { id, items: ReadOnlyArray::from_array(items) }
}

///|
pub impl @json.FromJson for ThreadItem with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "thread item must be an object"))
  }
  let item_type : String = @json.from_json(
    thread_item_type_lens.get_or_json_decode_error(json, path),
    path=thread_item_type_lens.add_to_json_path(path),
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
      raise thread_item_type_lens.json_decode_error(
        path,
        "unsupported thread item type: \{item_type}",
      )
  }
}
