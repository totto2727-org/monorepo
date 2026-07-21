# MoonBit Concurrency

> Document type: concrete MoonBit implementation guidance.

## Concurrency rules

An async call blocks its caller until it returns. Async syntax alone therefore does not make repeated I/O concurrent. Before writing a loop or a sequence of async calls, identify which operations are independent and start those operations together.

The rules below follow the official `moonbitlang/async` implementation pinned by this repository:

- [`all` implementation and contract](https://github.com/moonbitlang/async/blob/v0.19.2/src/async.mbt)
- [`all` ordering, concurrency-limit, failure, and cancellation tests](https://github.com/moonbitlang/async/blob/v0.19.2/src/all_any_test.mbt)

### Use `@async.all` for homogeneous independent work

Map each input to an `async () -> T` task and pass the tasks to `@async.all`. It starts every task concurrently by default and returns results in input order, even when completion order differs.

```mbt check
async fn read_documents(paths : Array[String]) -> Array[String] {
  @async.all(
    paths.map(path => () => @fs.read_file(path).text()),
  )
}
```

Use this shape for independent file reads or writes, directory checks, HTTP requests, subprocesses operating on distinct resources, and per-entry resolution. Flatten or filter the ordered result after `@async.all`; do not mutate a shared result array from the tasks.

### Use a task group for heterogeneous independent work

When independent operations have different result types, spawn them in one `@async.with_task_group` and wait for each handle before returning from the group.

```mbt check
async fn load_inputs(
  config_path : String,
  lock_path : String,
) -> (String, Bool) {
  @async.with_task_group(group => {
    let config_task = group.spawn(() => @fs.read_file(config_path).text())
    let lock_task = group.spawn(() => @fs.exists(lock_path))
    (config_task.wait(), lock_task.wait())
  })
}
```

Do not use a background task for work whose result or failure belongs to the current operation. Structured tasks must finish or be cancelled before their owning scope returns.

### Keep real dependencies sequential

Parallelism is incorrect when one operation supplies state required by the next operation. Keep such steps visibly ordered:

```mbt check
async fn resolve_revision(source : String) -> String {
  let repo_dir = ensure_repo(source)
  commit_hash(repo_dir)
}
```

Typical dependencies include creating a directory before writing inside it, cloning a repository before reading its revision, and writing a lock file before invoking a consumer that reads that file.

### Prevent shared-resource races

Tasks may run concurrently only when their writes cannot target the same mutable resource. Before creating tasks:

- deduplicate identical output paths
- resolve and merge data concurrently, then apply deterministic conflict rules such as first-wins or last-wins before writing
- partition work by output directory, lock file, Git checkout, or cache entry
- serialize only the conflicting partition when order is part of the contract

Use `max_concurrent` to limit resource pressure or to serialize a known conflicting batch:

```mbt check
@async.all(tasks, max_concurrent=8) |> ignore
```

Do not use a concurrency limit as a substitute for identifying races. A limit greater than one still permits conflicting tasks to overlap; a limit of one is appropriate only when the original order must be retained and the batch cannot be partitioned safely.

### Preserve failure semantics

`@async.all` propagates the first task failure and cancels other running tasks. Do not catch and discard cancellation while implementing per-item recovery.

```mbt check
let result = resolve_item(item) catch {
  err if @async.is_being_cancelled() => raise err
  err => {
    println("Skipped \{item}: \{err}")
    None
  }
}
```

Catch an ordinary item failure only when skipping that item is part of the operation's contract. Otherwise, let the error propagate so the caller observes the failure.

### Preserve cancellation semantics

When one task fails, `@async.all` cancels its running siblings. Per-item recovery must re-raise cancellation instead of treating it as a skippable item failure.

### Review the concurrency contract

For every async traversal, verify all of the following:

- independent work uses `@async.all` or a task group instead of sequential `for` or recursive traversal
- dependent work remains sequential
- result ordering matches the input contract
- duplicate or shared targets cannot race
- concurrency is capped when the task count can be large or the external resource has a known limit
- failure propagation is preserved
- cancellation is not swallowed

### Test the concurrency contract

Tests should cover observable ordering, duplicate-target resolution, failure propagation, and any conflict path that intentionally falls back to sequential execution.
