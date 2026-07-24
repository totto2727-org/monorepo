// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/turnOptions.ts

///| Options applied to one turn.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/turnOptions.ts#L1-L6
///| Type difference: Json replaces TypeScript unknown, and cancelling the owning MoonBit task replaces AbortSignal.
pub(all) struct TurnOptions {
  output_schema : Json?
} derive(Debug, Eq)

///| Constructs the same output-schema option as the upstream object type.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/turnOptions.ts#L1-L6
///| Type difference: MoonBit structs require a constructor to provide the upstream empty-object default.
pub fn TurnOptions::TurnOptions(output_schema? : Json) -> TurnOptions {
  { output_schema, }
}
