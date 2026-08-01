// MoonBit-only FromJson implementations required because TypeScript casts parsed JSON to ThreadItem.
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L103
// Item shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L5-L128
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

///|
pub impl @json.FromJson for CommandExecutionStatus with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "in_progress" => InProgress
    "completed" => Completed
    "failed" => Failed
    _ =>
      moonbit_internal_decode_error(
        path,
        "unsupported command execution status: \{value}",
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
      moonbit_internal_decode_error(
        path,
        "unsupported patch change kind: \{value}",
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
      moonbit_internal_decode_error(
        path,
        "unsupported patch apply status: \{value}",
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
      moonbit_internal_decode_error(
        path,
        "unsupported MCP tool call status: \{value}",
      )
  }
}

///|
pub impl @json.FromJson for FileUpdateChange with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "file update")
  {
    path: @path.Path(
      moonbit_internal_required_string(object, "path", path, "file update"),
    ),
    kind: @json.from_json(
      moonbit_internal_required_json(object, "kind", path, "file update"),
      path=path.add_key("kind"),
    ),
  }
}

///|
pub impl @json.FromJson for TodoItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "todo item")
  {
    text: moonbit_internal_required_string(object, "text", path, "todo item"),
    completed: moonbit_internal_required_bool(
      object, "completed", path, "todo item",
    ),
  }
}

///|
pub impl @json.FromJson for McpToolCallResult with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "MCP tool result")
  {
    content: ReadOnlyArray::from_array(
      moonbit_internal_required_array(
        object, "content", path, "MCP tool result",
      ),
    ),
    meta: moonbit_internal_optional_json(object, "_meta"),
    structured_content: moonbit_internal_required_json(
      object, "structured_content", path, "MCP tool result",
    ),
  }
}

///|
pub impl @json.FromJson for McpToolCallError with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "MCP tool error")
  {
    message: moonbit_internal_required_string(
      object, "message", path, "MCP tool error",
    ),
  }
}

///|
pub impl @json.FromJson for AgentMessageItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "agent_message")
  {
    id: moonbit_internal_required_string(object, "id", path, "agent_message"),
    text: moonbit_internal_required_string(
      object, "text", path, "agent_message",
    ),
  }
}

///|
pub impl @json.FromJson for ReasoningItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "reasoning")
  {
    id: moonbit_internal_required_string(object, "id", path, "reasoning"),
    text: moonbit_internal_required_string(object, "text", path, "reasoning"),
  }
}

///|
pub impl @json.FromJson for CommandExecutionItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "command_execution")
  {
    id: moonbit_internal_required_string(
      object, "id", path, "command_execution",
    ),
    command: moonbit_internal_required_string(
      object, "command", path, "command_execution",
    ),
    aggregated_output: moonbit_internal_required_string(
      object, "aggregated_output", path, "command_execution",
    ),
    exit_code: moonbit_internal_optional_int(
      object, "exit_code", path, "command_execution",
    ),
    status: @json.from_json(
      moonbit_internal_required_json(
        object, "status", path, "command_execution",
      ),
      path=path.add_key("status"),
    ),
  }
}

///|
pub impl @json.FromJson for FileChangeItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "file_change")
  let changes = moonbit_internal_required_array(
    object, "changes", path, "file_change",
  )
  {
    id: moonbit_internal_required_string(object, "id", path, "file_change"),
    changes: ReadOnlyArray::from_array(
      changes.mapi((index, value) => {
        @json.from_json(value, path=path.add_key("changes").add_index(index))
      }),
    ),
    status: @json.from_json(
      moonbit_internal_required_json(object, "status", path, "file_change"),
      path=path.add_key("status"),
    ),
  }
}

///|
pub impl @json.FromJson for McpToolCallItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "mcp_tool_call")
  {
    id: moonbit_internal_required_string(object, "id", path, "mcp_tool_call"),
    server: moonbit_internal_required_string(
      object, "server", path, "mcp_tool_call",
    ),
    tool: moonbit_internal_required_string(
      object, "tool", path, "mcp_tool_call",
    ),
    arguments: moonbit_internal_required_json(
      object, "arguments", path, "mcp_tool_call",
    ),
    result: match moonbit_internal_optional_json(object, "result") {
      Some(value) => Some(@json.from_json(value, path=path.add_key("result")))
      None => None
    },
    error: match moonbit_internal_optional_json(object, "error") {
      Some(value) => Some(@json.from_json(value, path=path.add_key("error")))
      None => None
    },
    status: @json.from_json(
      moonbit_internal_required_json(object, "status", path, "mcp_tool_call"),
      path=path.add_key("status"),
    ),
  }
}

///|
pub impl @json.FromJson for WebSearchItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "web_search")
  {
    id: moonbit_internal_required_string(object, "id", path, "web_search"),
    query: moonbit_internal_required_string(object, "query", path, "web_search"),
  }
}

///|
pub impl @json.FromJson for TodoListItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "todo_list")
  let items = moonbit_internal_required_array(
    object, "items", path, "todo_list",
  )
  {
    id: moonbit_internal_required_string(object, "id", path, "todo_list"),
    items: ReadOnlyArray::from_array(
      items.mapi((index, value) => {
        @json.from_json(value, path=path.add_key("items").add_index(index))
      }),
    ),
  }
}

///|
pub impl @json.FromJson for ErrorItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "error")
  {
    id: moonbit_internal_required_string(object, "id", path, "error"),
    message: moonbit_internal_required_string(object, "message", path, "error"),
  }
}

///|
pub impl @json.FromJson for ThreadItem with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "thread item")
  let item_type = moonbit_internal_required_string(
    object, "type", path, "thread item",
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
      moonbit_internal_decode_error(
        path.add_key("type"),
        "unsupported thread item type: \{item_type}",
      )
  }
}
