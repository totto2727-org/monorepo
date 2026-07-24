///| Errors raised by the Codex SDK at configuration, protocol, and process boundaries.
pub(all) suberror CodexSdkError {
  InvalidConfig(path~ : String, message~ : String)
  InvalidOutputSchema(message~ : String)
  InvalidEvent(message~ : String)
  TurnFailed(message~ : String)
  ExecFailed(code~ : Int, stderr~ : String)
} derive(Debug, Eq)
