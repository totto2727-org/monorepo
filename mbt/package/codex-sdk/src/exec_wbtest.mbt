// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/exec.test.ts

///| Runtime substitution for the upstream legacy package-layout fallback test.

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/exec.test.ts#L166

///|
/// Runtime difference: MoonBit resolves the unqualified `codex` executable through PATH.
test "CodexExec path - falls back to the PATH executable" {
  let exec = CodexExec::CodexExec(None, None, None)
  inspect(exec.executable_path.to_string(), content="codex")
}
