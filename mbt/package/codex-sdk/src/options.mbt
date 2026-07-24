///| A recursively typed Codex CLI configuration value.
pub(all) enum CodexConfigValue {
  ConfigString(String)
  ConfigInt(Int)
  ConfigDouble(Double)
  ConfigBool(Bool)
  ConfigArray(Array[CodexConfigValue])
  ConfigObject(Map[String, CodexConfigValue])
} derive(Debug, Eq)

///| A JSON-shaped object whose values are serialized as TOML CLI overrides.
pub type CodexConfigObject = Map[String, CodexConfigValue]

///| Options shared by every thread created from a Codex client.
pub(all) struct CodexOptions {
  codex_path_override : @path.Path?
  base_url : String?
  api_key : String?
  config : CodexConfigObject?
  env : Map[String, String]?
} derive(Eq)

///| Constructs Codex client options.
pub fn CodexOptions::CodexOptions(
  codex_path_override? : @path.Path,
  base_url? : String,
  api_key? : String,
  config? : CodexConfigObject,
  env? : Map[String, String],
) -> CodexOptions {
  { codex_path_override, base_url, api_key, config, env }
}

///| Controls when Codex may request command approval.
pub(all) enum ApprovalMode {
  Never
  OnRequest
  OnFailure
  Untrusted
} derive(Debug, Eq)

///| Returns the Codex CLI representation of an approval mode.
pub fn ApprovalMode::to_string(self : ApprovalMode) -> String {
  match self {
    Never => "never"
    OnRequest => "on-request"
    OnFailure => "on-failure"
    Untrusted => "untrusted"
  }
}

///| Selects the filesystem sandbox applied to a thread.
pub(all) enum SandboxMode {
  ReadOnly
  WorkspaceWrite
  DangerFullAccess
} derive(Debug, Eq)

///| Returns the Codex CLI representation of a sandbox mode.
pub fn SandboxMode::to_string(self : SandboxMode) -> String {
  match self {
    ReadOnly => "read-only"
    WorkspaceWrite => "workspace-write"
    DangerFullAccess => "danger-full-access"
  }
}

///| Selects the model reasoning effort for a thread.
pub(all) enum ModelReasoningEffort {
  Minimal
  Low
  Medium
  High
  XHigh
} derive(Debug, Eq)

///| Returns the Codex CLI representation of a reasoning effort.
pub fn ModelReasoningEffort::to_string(
  self : ModelReasoningEffort,
) -> String {
  match self {
    Minimal => "minimal"
    Low => "low"
    Medium => "medium"
    High => "high"
    XHigh => "xhigh"
  }
}

///| Selects the web-search source used by a thread.
pub(all) enum WebSearchMode {
  Disabled
  Cached
  Live
} derive(Debug, Eq)

///| Returns the Codex CLI representation of a web-search mode.
pub fn WebSearchMode::to_string(self : WebSearchMode) -> String {
  match self {
    Disabled => "disabled"
    Cached => "cached"
    Live => "live"
  }
}

///| Options applied to every turn in one thread.
pub(all) struct ThreadOptions {
  model : String?
  sandbox_mode : SandboxMode?
  working_directory : @path.Path?
  skip_git_repo_check : Bool?
  model_reasoning_effort : ModelReasoningEffort?
  network_access_enabled : Bool?
  web_search_mode : WebSearchMode?
  web_search_enabled : Bool?
  approval_policy : ApprovalMode?
  additional_directories : Array[@path.Path]
} derive(Eq)

///| Constructs thread options.
pub fn ThreadOptions::ThreadOptions(
  model? : String,
  sandbox_mode? : SandboxMode,
  working_directory? : @path.Path,
  skip_git_repo_check? : Bool,
  model_reasoning_effort? : ModelReasoningEffort,
  network_access_enabled? : Bool,
  web_search_mode? : WebSearchMode,
  web_search_enabled? : Bool,
  approval_policy? : ApprovalMode,
  additional_directories? : Array[@path.Path] = [],
) -> ThreadOptions {
  {
    model,
    sandbox_mode,
    working_directory,
    skip_git_repo_check,
    model_reasoning_effort,
    network_access_enabled,
    web_search_mode,
    web_search_enabled,
    approval_policy,
    additional_directories,
  }
}

///| Options applied to one turn.
///
/// Cancelling the MoonBit task running the turn is equivalent to aborting the TypeScript SDK's `AbortSignal`.
pub(all) struct TurnOptions {
  output_schema : Json?
} derive(Debug, Eq)

///| Constructs per-turn options.
pub fn TurnOptions::TurnOptions(output_schema? : Json) -> TurnOptions {
  { output_schema }
}
