// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts

// MoonBit-only deterministic synchronization for the upstream setTimeout-based execution test.
// Corresponding upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L82
async fn moonbit_internal_wait_for_test_file(path : String) -> Unit raise {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

// MoonBit-only assertion adapter for AbortSignal rejection semantics.
// Corresponding upstream cancellation assertions: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L21-L140
async fn moonbit_internal_wait_for_cancellation(
  task : @async.Task[Unit],
) -> Bool {
  try {
    task.wait()
    false
  } catch {
    error => @async.is_cancellation_error(error)
  }
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L21
async test "Codex run - cancels when task is cancelled" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() { thread.run(Prompt("Hello")) |> ignore },
        allow_failure=true,
      )
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L43
async test "Codex runStreamed - cancels when task is cancelled" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    let events : Array[ThreadEvent] = []
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          thread.run_streamed(
            Prompt("Hello"),
            async fn(event) {
              events.push(event)
              @async.pause()
            },
          )
        },
        allow_failure=true,
      )
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
    assert_eq(events.length(), 0)
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L82
async test "Codex run - cancels during execution" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() { thread.run(Prompt("Hello")) |> ignore },
        allow_failure=true,
      )
      moonbit_internal_wait_for_test_file("\{fixture.record_directory}/args.1")
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L108
async test "Codex runStreamed - cancels during iteration" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    let started : @aqueue.Queue[Unit] = @aqueue.Queue(
      kind=@aqueue.Unbounded,
    )
    let release : @aqueue.Queue[Unit] = @aqueue.Queue(
      kind=@aqueue.Unbounded,
    )
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          thread.run_streamed(
            Prompt("Hello"),
            async fn(_) {
              started.put(())
              release.get()
            },
          )
        },
        allow_failure=true,
      )
      started.get()
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L143
async test "Codex run - completes normally when task is not cancelled" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let result = client.start_thread().run(Prompt("Hello"))
    inspect(result.final_response, content="Hi!")
  })
}
