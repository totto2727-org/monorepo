///|
test "RunOptions 1 - rejects invalid limits before graph execution" {
  try RunOptions::RunOptions(max_steps=0) catch {
    MaxStepsMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected MaxStepsMustBePositive")
  } noraise {
    _ => fail("expected MaxStepsMustBePositive")
  }
  try RunOptions::RunOptions(node_timeout_ms=0) catch {
    NodeTimeoutMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected NodeTimeoutMustBePositive")
  } noraise {
    _ => fail("expected NodeTimeoutMustBePositive")
  }
  try RunOptions::RunOptions(cleanup_timeout_ms=0) catch {
    CleanupTimeoutMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected CleanupTimeoutMustBePositive")
  } noraise {
    _ => fail("expected CleanupTimeoutMustBePositive")
  }
}
