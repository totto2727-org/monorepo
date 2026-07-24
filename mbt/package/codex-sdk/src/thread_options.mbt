// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts

///| Controls when Codex may request command approval.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L1
///| Type difference: MoonBit uses an enum instead of a string-literal union.
pub(all) enum ApprovalMode {
  Never
  OnRequest
  OnFailure
  Untrusted
} derive(Debug, Eq)

///| Returns the upstream CLI string for an approval mode.
///| Upstream values: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L1
///| Type difference: the explicit conversion is required for the MoonBit enum.
pub fn ApprovalMode::to_string(self : ApprovalMode) -> String {
  match self {
    Never => "never"
    OnRequest => "on-request"
    OnFailure => "on-failure"
    Untrusted => "untrusted"
  }
}

///| Selects the filesystem sandbox applied to a thread.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L3
///| Type difference: MoonBit uses an enum instead of a string-literal union.
pub(all) enum SandboxMode {
  ReadOnly
  WorkspaceWrite
  DangerFullAccess
} derive(Debug, Eq)

///| Returns the upstream CLI string for a sandbox mode.
///| Upstream values: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L3
///| Type difference: the explicit conversion is required for the MoonBit enum.
pub fn SandboxMode::to_string(self : SandboxMode) -> String {
  match self {
    ReadOnly => "read-only"
    WorkspaceWrite => "workspace-write"
    DangerFullAccess => "danger-full-access"
  }
}

///| Selects the model reasoning effort for a thread.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L5
///| Type difference: MoonBit uses an enum instead of a string-literal union.
pub(all) enum ModelReasoningEffort {
  Minimal
  Low
  Medium
  High
  XHigh
} derive(Debug, Eq)

///| Returns the upstream CLI string for a reasoning effort.
///| Upstream values: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L5
///| Type difference: the explicit conversion is required for the MoonBit enum.
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
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L7
///| Type difference: MoonBit uses an enum instead of a string-literal union.
pub(all) enum WebSearchMode {
  Disabled
  Cached
  Live
} derive(Debug, Eq)

///| Returns the upstream CLI string for a web-search mode.
///| Upstream values: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L7
///| Type difference: the explicit conversion is required for the MoonBit enum.
pub fn WebSearchMode::to_string(self : WebSearchMode) -> String {
  match self {
    Disabled => "disabled"
    Cached => "cached"
    Live => "live"
  }
}

///| Controls one persisted thread.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L9-L20
///| Type difference: filesystem strings are represented by Path.
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

///| Constructs the same optional ThreadOptions fields as the upstream object type.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/threadOptions.ts#L9-L20
///| Type difference: MoonBit structs require a constructor to provide the upstream empty-object defaults.
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
