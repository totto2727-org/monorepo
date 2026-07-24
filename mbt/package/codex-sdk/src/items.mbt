///| The status of a command execution.
pub(all) enum CommandExecutionStatus {
  InProgress
  Completed
  Failed
} derive(Debug, Eq)

///| A command executed by the agent.
pub(all) struct CommandExecutionItem {
  id : String
  command : String
  aggregated_output : String
  exit_code : Int?
  status : CommandExecutionStatus
} derive(Debug, Eq)

///| The kind of a file update.
pub(all) enum PatchChangeKind {
  Add
  Delete
  Update
} derive(Debug, Eq)

///| One file update in an applied patch.
pub(all) struct FileUpdateChange {
  path : @path.Path
  kind : PatchChangeKind
} derive(Eq)

///| The terminal status of a patch application.
pub(all) enum PatchApplyStatus {
  PatchCompleted
  PatchFailed
} derive(Debug, Eq)

///| A set of file changes emitted after a patch succeeds or fails.
pub(all) struct FileChangeItem {
  id : String
  changes : Array[FileUpdateChange]
  status : PatchApplyStatus
} derive(Eq)

///| The status of an MCP tool call.
pub(all) enum McpToolCallStatus {
  McpInProgress
  McpCompleted
  McpFailed
} derive(Debug, Eq)

///| The successful result of an MCP tool call.
pub(all) struct McpToolCallResult {
  content : Array[Json]
  meta : Json?
  structured_content : Json
} derive(Debug, Eq)

///| The failure returned by an MCP tool.
pub(all) struct McpToolCallError {
  message : String
} derive(Debug, Eq)

///| A call dispatched to an MCP server.
pub(all) struct McpToolCallItem {
  id : String
  server : String
  tool : String
  arguments : Json
  result : McpToolCallResult?
  error : McpToolCallError?
  status : McpToolCallStatus
} derive(Debug, Eq)

///| A natural-language or structured response emitted by the agent.
pub(all) struct AgentMessageItem {
  id : String
  text : String
} derive(Debug, Eq)

///| An agent reasoning summary.
pub(all) struct ReasoningItem {
  id : String
  text : String
} derive(Debug, Eq)

///| A web search request made by the agent.
pub(all) struct WebSearchItem {
  id : String
  query : String
} derive(Debug, Eq)

///| A non-fatal error surfaced as a thread item.
pub(all) struct ErrorItem {
  id : String
  message : String
} derive(Debug, Eq)

///| One entry in the agent's running to-do list.
pub(all) struct TodoItem {
  text : String
  completed : Bool
} derive(Debug, Eq)

///| The agent's current running to-do list.
pub(all) struct TodoListItem {
  id : String
  items : Array[TodoItem]
} derive(Debug, Eq)

///| Canonical union of thread items and their type-specific payloads.
pub(all) enum ThreadItem {
  AgentMessage(AgentMessageItem)
  Reasoning(ReasoningItem)
  CommandExecution(CommandExecutionItem)
  FileChange(FileChangeItem)
  McpToolCall(McpToolCallItem)
  WebSearch(WebSearchItem)
  TodoList(TodoListItem)
  Error(ErrorItem)
} derive(Eq)
