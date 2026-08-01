// MoonBit-only tests for the explicit item decoder required by the language type system.
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L103
// Item shapes under test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L5-L128

///|
fn item_decode_error(source : String) -> String {
  try {
    let item : ThreadItem = @json.from_json(@json.parse(source))
    item |> ignore
    "no error"
  } catch {
    @json.JsonDecodeError((_, message)) => message
    error => "unexpected:\{error}"
  }
}

///|
test "MoonBit item decoder - decodes agent messages" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"message-1\",\"type\":\"agent_message\",\"text\":\"hello\"}",
    ),
  )
  match item {
    AgentMessage(item) => {
      inspect(item.id, content="message-1")
      inspect(item.text, content="hello")
    }
    _ => fail("expected agent message")
  }
}

///|
test "MoonBit item decoder - decodes reasoning items" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"reasoning-1\",\"type\":\"reasoning\",\"text\":\"analysis\"}",
    ),
  )
  match item {
    Reasoning(item) => {
      inspect(item.id, content="reasoning-1")
      inspect(item.text, content="analysis")
    }
    _ => fail("expected reasoning item")
  }
}

///|
test "MoonBit item decoder - decodes command executions" {
  let completed_item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"command-1\",\"type\":\"command_execution\",\"command\":\"pwd\",\"aggregated_output\":\"/tmp\\n\",\"exit_code\":0,\"status\":\"completed\"}",
    ),
  )
  match completed_item {
    CommandExecution(item) => {
      inspect(item.id, content="command-1")
      inspect(item.command, content="pwd")
      inspect(item.aggregated_output, content="/tmp\n")
      assert_eq(item.exit_code, Some(0))
      assert_eq(item.status, Completed)
    }
    _ => fail("expected command execution")
  }
  let in_progress_item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"command-2\",\"type\":\"command_execution\",\"command\":\"sleep 1\",\"aggregated_output\":\"\",\"exit_code\":null,\"status\":\"in_progress\"}",
    ),
  )
  match in_progress_item {
    CommandExecution(item) => {
      assert_eq(item.exit_code, None)
      assert_eq(item.status, InProgress)
    }
    _ => fail("expected command execution")
  }
}

///|
test "MoonBit item decoder - decodes file changes" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"patch-1\",\"type\":\"file_change\",\"changes\":[{\"path\":\"new.txt\",\"kind\":\"add\"},{\"path\":\"old.txt\",\"kind\":\"delete\"},{\"path\":\"same.txt\",\"kind\":\"update\"}],\"status\":\"failed\"}",
    ),
  )
  match item {
    FileChange(item) => {
      inspect(item.id, content="patch-1")
      assert_eq(item.status, PatchFailed)
      inspect(item.changes.length(), content="3")
      inspect("\{item.changes[0].path}", content="new.txt")
      assert_eq(item.changes[0].kind, Add)
      assert_eq(item.changes[1].kind, Delete)
      assert_eq(item.changes[2].kind, Update)
    }
    _ => fail("expected file change")
  }
}

///|
test "MoonBit item decoder - decodes successful MCP tool calls" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"mcp-1\",\"type\":\"mcp_tool_call\",\"server\":\"docs\",\"tool\":\"search\",\"arguments\":{\"query\":\"MoonBit\"},\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"result\"}],\"_meta\":{\"source\":\"official\"},\"structured_content\":{\"count\":1}},\"error\":null,\"status\":\"completed\"}",
    ),
  )
  match item {
    McpToolCall(item) => {
      inspect(item.id, content="mcp-1")
      inspect(item.server, content="docs")
      inspect(item.tool, content="search")
      inspect(item.arguments.stringify(), content="{\"query\":\"MoonBit\"}")
      assert_eq(item.status, McpCompleted)
      assert_eq(item.error, None)
      match item.result {
        Some(result) => {
          inspect(result.content.length(), content="1")
          inspect(
            result.structured_content.stringify(),
            content="{\"count\":1}",
          )
          match result.meta {
            Some(meta) =>
              inspect(meta.stringify(), content="{\"source\":\"official\"}")
            None => fail("expected MCP result metadata")
          }
        }
        None => fail("expected MCP result")
      }
    }
    _ => fail("expected MCP tool call")
  }
}

///|
test "MoonBit item decoder - decodes failed MCP tool calls" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"mcp-2\",\"type\":\"mcp_tool_call\",\"server\":\"docs\",\"tool\":\"search\",\"arguments\":{},\"result\":null,\"error\":{\"message\":\"unavailable\"},\"status\":\"failed\"}",
    ),
  )
  match item {
    McpToolCall(item) => {
      assert_eq(item.status, McpFailed)
      assert_eq(item.result, None)
      match item.error {
        Some(error) => inspect(error.message, content="unavailable")
        None => fail("expected MCP error")
      }
    }
    _ => fail("expected MCP tool call")
  }
}

///|
test "MoonBit item decoder - decodes web searches" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"search-1\",\"type\":\"web_search\",\"query\":\"MoonBit async\"}",
    ),
  )
  match item {
    WebSearch(item) => {
      inspect(item.id, content="search-1")
      inspect(item.query, content="MoonBit async")
    }
    _ => fail("expected web search")
  }
}

///|
test "MoonBit item decoder - decodes todo lists" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"todo-1\",\"type\":\"todo_list\",\"items\":[{\"text\":\"port SDK\",\"completed\":true},{\"text\":\"test decoder\",\"completed\":false}]}",
    ),
  )
  match item {
    TodoList(item) => {
      inspect(item.id, content="todo-1")
      inspect(item.items.length(), content="2")
      inspect(item.items[0].text, content="port SDK")
      assert_true(item.items[0].completed)
      assert_false(item.items[1].completed)
    }
    _ => fail("expected todo list")
  }
}

///|
test "MoonBit item decoder - decodes error items" {
  let item : ThreadItem = @json.from_json(
    @json.parse(
      "{\"id\":\"error-1\",\"type\":\"error\",\"message\":\"recoverable\"}",
    ),
  )
  match item {
    Error(item) => {
      inspect(item.id, content="error-1")
      inspect(item.message, content="recoverable")
    }
    _ => fail("expected error item")
  }
}

///|
test "MoonBit item decoder - rejects unknown item types" {
  inspect(
    item_decode_error("{\"id\":\"unknown-1\",\"type\":\"unknown\"}"),
    content="unsupported thread item type: unknown",
  )
}

///|
test "MoonBit item decoder - rejects unknown item statuses" {
  inspect(
    item_decode_error(
      "{\"id\":\"command-1\",\"type\":\"command_execution\",\"command\":\"pwd\",\"aggregated_output\":\"\",\"exit_code\":0,\"status\":\"queued\"}",
    ),
    content="unsupported command execution status: queued",
  )
}

///|
test "MoonBit item decoder - rejects missing required fields" {
  inspect(
    item_decode_error("{\"id\":\"message-1\",\"type\":\"agent_message\"}"),
    content="Missing field text",
  )
}

///|
test "MoonBit item decoder - rejects non-object items" {
  inspect(item_decode_error("[]"), content="thread item must be an object")
}
