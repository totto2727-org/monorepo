// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts

///| The status of a command execution.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L5-L6

///|
/// Type difference: MoonBit uses an enum instead of a string-literal union.
pub enum CommandExecutionStatus {
  InProgress
  Completed
  Failed
} derive(Debug, Eq)

///| A command executed by the agent.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L8-L20
pub struct CommandExecutionItem {
  id : String
  command : String
  aggregated_output : String
  exit_code : Int?
  status : CommandExecutionStatus
} derive(Debug, Eq)

///| The kind of a file update.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L22-L23

///|
/// Type difference: MoonBit uses an enum instead of a string-literal union.
pub enum PatchChangeKind {
  Add
  Delete
  Update
} derive(Debug, Eq)

///| One file update in an applied patch.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L25-L29

///|
/// Type difference: filesystem strings are represented by Path.
pub struct FileUpdateChange {
  path : @path.Path
  kind : PatchChangeKind
} derive(Eq)

///| The terminal status of a patch application.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L31-L32

///|
/// Type difference: MoonBit uses an enum instead of a string-literal union.
pub enum PatchApplyStatus {
  PatchCompleted
  PatchFailed
} derive(Debug, Eq)

///| A set of file changes emitted after a patch succeeds or fails.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L34-L42
pub struct FileChangeItem {
  id : String
  changes : ReadOnlyArray[FileUpdateChange]
  status : PatchApplyStatus
} derive(Eq)

///| The status of an MCP tool call.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L44-L45

///|
/// Type difference: MoonBit uses an enum instead of a string-literal union.
pub enum McpToolCallStatus {
  McpInProgress
  McpCompleted
  McpFailed
} derive(Debug, Eq)

///| The successful result of an MCP tool call.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L60-L65

///|
/// Type difference: explicit structs replace inline TypeScript object types.
pub struct McpToolCallResult {
  content : ReadOnlyArray[Json]
  meta : Json?
  structured_content : Json
} derive(Debug, Eq)

///| The failure returned by an MCP tool.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L66-L69

///|
/// Type difference: explicit structs replace inline TypeScript object types.
pub struct McpToolCallError {
  message : String
} derive(Debug, Eq, FromJson)

///| A call dispatched to an MCP server.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L47-L72
pub struct McpToolCallItem {
  id : String
  server : String
  tool : String
  arguments : Json
  result : McpToolCallResult?
  error : McpToolCallError?
  status : McpToolCallStatus
} derive(Debug, Eq)

///| A natural-language or structured response emitted by the agent.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L74-L80
pub struct AgentMessageItem {
  id : String
  text : String
} derive(Debug, Eq, FromJson)

///| An agent reasoning summary.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L82-L87
pub struct ReasoningItem {
  id : String
  text : String
} derive(Debug, Eq, FromJson)

///| A web search request made by the agent.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L89-L94
pub struct WebSearchItem {
  id : String
  query : String
} derive(Debug, Eq, FromJson)

///| A non-fatal error surfaced as a thread item.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L96-L101
pub struct ErrorItem {
  id : String
  message : String
} derive(Debug, Eq, FromJson)

///| One entry in the agent's running to-do list.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L103-L107
pub struct TodoItem {
  text : String
  completed : Bool
} derive(Debug, Eq, FromJson)

///| The agent's current running to-do list.

///|
/// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L109-L117
pub struct TodoListItem {
  id : String
  items : ReadOnlyArray[TodoItem]
} derive(Debug, Eq)

///| Canonical union of thread items and their type-specific payloads.

///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/items.ts#L119-L128

///|
/// Type difference: MoonBit uses an enum instead of a discriminated object union.
pub enum ThreadItem {
  AgentMessage(AgentMessageItem)
  Reasoning(ReasoningItem)
  CommandExecution(CommandExecutionItem)
  FileChange(FileChangeItem)
  McpToolCall(McpToolCallItem)
  WebSearch(WebSearchItem)
  TodoList(TodoListItem)
  Error(ErrorItem)
} derive(Eq)
