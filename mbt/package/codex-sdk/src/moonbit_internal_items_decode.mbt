// MoonBit-only implementation of the explicit item decoding required by the language type system.
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L103
// Item shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L5-L128
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

fn moonbit_internal_command_execution_status_from_string(
  value : String,
) -> CommandExecutionStatus raise CodexSdkError {
  match value {
    "in_progress" => InProgress
    "completed" => Completed
    "failed" => Failed
    _ => raise InvalidEvent(message="unsupported command execution status: \{value}")
  }
}

fn moonbit_internal_patch_change_kind_from_string(
  value : String,
) -> PatchChangeKind raise CodexSdkError {
  match value {
    "add" => Add
    "delete" => Delete
    "update" => Update
    _ => raise InvalidEvent(message="unsupported patch change kind: \{value}")
  }
}

fn moonbit_internal_patch_apply_status_from_string(
  value : String,
) -> PatchApplyStatus raise CodexSdkError {
  match value {
    "completed" => PatchCompleted
    "failed" => PatchFailed
    _ => raise InvalidEvent(message="unsupported patch apply status: \{value}")
  }
}

fn moonbit_internal_mcp_tool_call_status_from_string(
  value : String,
) -> McpToolCallStatus raise CodexSdkError {
  match value {
    "in_progress" => McpInProgress
    "completed" => McpCompleted
    "failed" => McpFailed
    _ => raise InvalidEvent(message="unsupported MCP tool call status: \{value}")
  }
}

fn moonbit_internal_file_update_change_from_json(
  json : Json,
) -> FileUpdateChange raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "file update")
  {
    path: @path.Path(
      moonbit_internal_required_string(object, "path", "file update"),
    ),
    kind: moonbit_internal_patch_change_kind_from_string(
      moonbit_internal_required_string(object, "kind", "file update"),
    ),
  }
}

fn moonbit_internal_todo_item_from_json(
  json : Json,
) -> TodoItem raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "todo item")
  {
    text: moonbit_internal_required_string(object, "text", "todo item"),
    completed: moonbit_internal_required_bool(object, "completed", "todo item"),
  }
}

fn moonbit_internal_mcp_tool_call_result_from_json(
  json : Json,
) -> McpToolCallResult raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "MCP tool result")
  {
    content: moonbit_internal_required_array(
      object,
      "content",
      "MCP tool result",
    ),
    meta: moonbit_internal_optional_json(object, "_meta"),
    structured_content: moonbit_internal_required_json(
      object,
      "structured_content",
      "MCP tool result",
    ),
  }
}

fn moonbit_internal_mcp_tool_call_error_from_json(
  json : Json,
) -> McpToolCallError raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "MCP tool error")
  {
    message: moonbit_internal_required_string(
      object,
      "message",
      "MCP tool error",
    ),
  }
}

fn moonbit_internal_thread_item_from_object(
  object : Map[String, Json],
) -> ThreadItem raise CodexSdkError {
  let item_type = moonbit_internal_required_string(object, "type", "thread item")
  let id = moonbit_internal_required_string(object, "id", item_type)
  match item_type {
    "agent_message" =>
      AgentMessage({
        id,
        text: moonbit_internal_required_string(object, "text", item_type),
      })
    "reasoning" =>
      Reasoning({
        id,
        text: moonbit_internal_required_string(object, "text", item_type),
      })
    "command_execution" =>
      CommandExecution({
        id,
        command: moonbit_internal_required_string(object, "command", item_type),
        aggregated_output: moonbit_internal_required_string(
          object,
          "aggregated_output",
          item_type,
        ),
        exit_code: moonbit_internal_optional_int(object, "exit_code", item_type),
        status: moonbit_internal_command_execution_status_from_string(
          moonbit_internal_required_string(object, "status", item_type),
        ),
      })
    "file_change" =>
      FileChange({
        id,
        changes: moonbit_internal_required_array(
          object,
          "changes",
          item_type,
        ).map(
          moonbit_internal_file_update_change_from_json,
        ),
        status: moonbit_internal_patch_apply_status_from_string(
          moonbit_internal_required_string(object, "status", item_type),
        ),
      })
    "mcp_tool_call" =>
      McpToolCall({
        id,
        server: moonbit_internal_required_string(object, "server", item_type),
        tool: moonbit_internal_required_string(object, "tool", item_type),
        arguments: moonbit_internal_required_json(object, "arguments", item_type),
        result: match moonbit_internal_optional_json(object, "result") {
          Some(value) =>
            Some(moonbit_internal_mcp_tool_call_result_from_json(value))
          None => None
        },
        error: match moonbit_internal_optional_json(object, "error") {
          Some(value) =>
            Some(moonbit_internal_mcp_tool_call_error_from_json(value))
          None => None
        },
        status: moonbit_internal_mcp_tool_call_status_from_string(
          moonbit_internal_required_string(object, "status", item_type),
        ),
      })
    "web_search" =>
      WebSearch({
        id,
        query: moonbit_internal_required_string(object, "query", item_type),
      })
    "todo_list" =>
      TodoList({
        id,
        items: moonbit_internal_required_array(object, "items", item_type).map(
          moonbit_internal_todo_item_from_json,
        ),
      })
    "error" =>
      Error({
        id,
        message: moonbit_internal_required_string(object, "message", item_type),
      })
    _ => raise InvalidEvent(message="unsupported thread item type: \{item_type}")
  }
}

fn moonbit_internal_thread_item_from_json(
  json : Json,
) -> ThreadItem raise CodexSdkError {
  moonbit_internal_thread_item_from_object(
    moonbit_internal_json_object(json, "thread item"),
  )
}
