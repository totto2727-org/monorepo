// MoonBit-only typed declarations for errors thrown inline by the TypeScript implementation.
// Upstream exec errors: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L227-L232
// Upstream event and turn errors: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L103
// Upstream output schema error: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/outputSchemaFile.ts#L10-L35
// This file is intentionally prefixed moonbit_internal_ because MoonBit requires declared error variants.

///| Errors raised by the Codex SDK at configuration, protocol, and process boundaries.
///| Type difference: named variants retain upstream failure boundaries while satisfying MoonBit's typed error system.
pub(all) suberror CodexSdkError {
  InvalidConfig(path~ : String, message~ : String)
  InvalidOutputSchema(message~ : String)
  InvalidEvent(message~ : String)
  TurnFailed(message~ : String)
  ExecFailed(code~ : Int, stderr~ : String)
} derive(Debug, Eq)
