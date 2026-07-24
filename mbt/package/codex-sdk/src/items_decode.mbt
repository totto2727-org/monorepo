fn command_execution_status_from_string(
  value : String,
) -> CommandExecutionStatus raise CodexSdkError {
  match value {
    "in_progress" => InProgress
    "completed" => Completed
    "failed" => Failed
    _ => raise InvalidEvent(message="unsupported command execution status: \{value}")
  }
}

fn patch_change_kind_from_string(
  value : String,
) -> PatchChangeKind raise CodexSdkError {
  match value {
    "add" => Add
    "delete" => Delete
    "update" => Update
    _ => raise InvalidEvent(message="unsupported patch change kind: \{value}")
  }
}

fn patch_apply_status_from_string(
  value : String,
) -> PatchApplyStatus raise CodexSdkError {
  match value {
    "completed" => PatchCompleted
    "failed" => PatchFailed
    _ => raise InvalidEvent(message="unsupported patch apply status: \{value}")
  }
}

fn mcp_tool_call_status_from_string(
  value : String,
) -> McpToolCallStatus raise CodexSdkError {
  match value {
    "in_progress" => McpInProgress
    "completed" => McpCompleted
    "failed" => McpFailed
    _ => raise InvalidEvent(message="unsupported MCP tool call status: \{value}")
  }
}

fn file_update_change_from_json(
  json : Json,
) -> FileUpdateChange raise CodexSdkError {
  let object = json_object(json, "file update")
  {
    path: @path.Path(required_string(object, "path", "file update")),
    kind: patch_change_kind_from_string(required_string(object, "kind", "file update")),
  }
}

fn todo_item_from_json(json : Json) -> TodoItem raise CodexSdkError {
  let object = json_object(json, "todo item")
  {
    text: required_string(object, "text", "todo item"),
    completed: required_bool(object, "completed", "todo item"),
  }
}

fn mcp_tool_call_result_from_json(
  json : Json,
) -> McpToolCallResult raise CodexSdkError {
  let object = json_object(json, "MCP tool result")
  {
    content: required_array(object, "content", "MCP tool result"),
    meta: optional_json(object, "_meta"),
    structured_content: required_json(object, "structured_content", "MCP tool result"),
  }
}

fn mcp_tool_call_error_from_json(
  json : Json,
) -> McpToolCallError raise CodexSdkError {
  let object = json_object(json, "MCP tool error")
  { message: required_string(object, "message", "MCP tool error") }
}

fn thread_item_from_object(
  object : Map[String, Json],
) -> ThreadItem raise CodexSdkError {
  let item_type = required_string(object, "type", "thread item")
  let id = required_string(object, "id", item_type)
  match item_type {
    "agent_message" =>
      AgentMessage({ id, text: required_string(object, "text", item_type) })
    "reasoning" =>
      Reasoning({ id, text: required_string(object, "text", item_type) })
    "command_execution" =>
      CommandExecution({
        id,
        command: required_string(object, "command", item_type),
        aggregated_output: required_string(object, "aggregated_output", item_type),
        exit_code: optional_int(object, "exit_code", item_type),
        status: command_execution_status_from_string(
          required_string(object, "status", item_type),
        ),
      })
    "file_change" =>
      FileChange({
        id,
        changes: required_array(object, "changes", item_type).map(
          file_update_change_from_json,
        ),
        status: patch_apply_status_from_string(
          required_string(object, "status", item_type),
        ),
      })
    "mcp_tool_call" =>
      McpToolCall({
        id,
        server: required_string(object, "server", item_type),
        tool: required_string(object, "tool", item_type),
        arguments: required_json(object, "arguments", item_type),
        result: match optional_json(object, "result") {
          Some(value) => Some(mcp_tool_call_result_from_json(value))
          None => None
        },
        error: match optional_json(object, "error") {
          Some(value) => Some(mcp_tool_call_error_from_json(value))
          None => None
        },
        status: mcp_tool_call_status_from_string(
          required_string(object, "status", item_type),
        ),
      })
    "web_search" =>
      WebSearch({ id, query: required_string(object, "query", item_type) })
    "todo_list" =>
      TodoList({
        id,
        items: required_array(object, "items", item_type).map(todo_item_from_json),
      })
    "error" => Error({ id, message: required_string(object, "message", item_type) })
    _ => raise InvalidEvent(message="unsupported thread item type: \{item_type}")
  }
}

///| Decodes one JSON thread item emitted by `codex exec --experimental-json`.
pub fn ThreadItem::from_json(json : Json) -> ThreadItem raise CodexSdkError {
  thread_item_from_object(json_object(json, "thread item"))
}
