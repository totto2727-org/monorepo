///|
fn is_declared_target(targets : ReadOnlyArray[NodeId], target : NodeId) -> Bool {
  for declared in targets {
    if declared == target {
      return true
    }
  }
  false
}

///|
fn attach_cleanup(primary : Error, cleanup : Error) -> Error {
  match primary {
    ResourceCleanupFailed(failure~) =>
      ResourceCleanupFailed(failure=RunFailure::{
        primary: failure.primary,
        cleanup: [..failure.cleanup, cleanup],
      })
    _ =>
      ResourceCleanupFailed(failure=RunFailure::{ primary, cleanup: [cleanup] })
  }
}

///|
async fn[S, P] execute_node(
  node : Node[S, P],
  context : NodeContext,
  state : S,
  timeout_ms : Int?,
) -> NodeOutput[P] {
  let execute = async fn() {
    (node.execute)(context, state) catch {
      error if @async.is_being_cancelled() ||
        @async.is_cancellation_error(error) => raise error
      error =>
        raise GraphRuntimeError::NodeFailed(
          node_id=context.node_id,
          step=context.step,
          cause=error,
        )
    }
  }
  match timeout_ms {
    Some(timeout_ms) =>
      @async.with_timeout(
        timeout_ms,
        execute,
        error=NodeTimedOut(
          node_id=context.node_id,
          step=context.step,
          timeout_ms~,
        ),
      )
    None => execute()
  }
}

///|
async fn[S, P] run_sequential(
  runtime : GraphRuntime[S, P],
  initial_state : S,
  options : RunOptions,
  run_id : RunId,
  group : @async.TaskGroup[Unit],
  resources : RuntimeResourceStore,
) -> RunResult[S] {
  let mut state = initial_state
  let mut current = runtime.graph.entry()
  let mut steps = 0
  while true {
    if steps >= options.max_steps {
      raise StepLimitExceeded(limit=options.max_steps)
    }
    steps = steps + 1
    let node = runtime.graph.get_node(current)
    let context = NodeContext::NodeContext(
      run_id,
      current,
      steps,
      group,
      events=runtime.events,
      resources~,
      deadline_ms?=options.node_timeout_ms.map(Int64::from_int),
    )
    runtime.events.try_emit(NodeStarted(run_id~, node_id=current, step=steps))
    let mut output : NodeOutput[P]? = None
    let mut primary : Error? = None
    try {
      output = Some(execute_node(node, context, state, options.node_timeout_ms))
    } catch {
      error if @async.is_being_cancelled() ||
        @async.is_cancellation_error(error) => primary = Some(error)
      error => {
        runtime.events.try_emit(
          NodeFailed(run_id~, node_id=current, step=steps, cause=error),
        )
        primary = Some(error)
      }
    }
    let cleanup = try {
      resources.release_node(current)
      None
    } catch {
      error => Some(error)
    }
    match (primary, cleanup) {
      (Some(error), Some(cleanup_error)) =>
        raise attach_cleanup(error, cleanup_error)
      (Some(error), None) => raise error
      (None, Some(cleanup_error)) =>
        raise ResourceCleanupFailed(failure=RunFailure::{
          primary: cleanup_error,
          cleanup: [],
        })
      (None, None) => ()
    }
    let output = match output {
      Some(output) => output
      None => abort("node attempt completed without output or error")
    }
    let completion = NodeCompletion::{
      node_id: current,
      value: output.value,
      artifacts: ReadOnlyArray::from_array([..output.artifacts]),
    }
    runtime.events.try_emit(
      NodeCompleted(run_id~, node_id=current, step=steps, completion~),
    )
    match output.patch {
      Some(patch) => {
        state = (runtime.graph.reducer.apply)(state, patch) catch {
          error => raise ReduceFailed(node_id=current, step=steps, cause=error)
        }
        runtime.events.try_emit(
          StateUpdated(run_id~, node_id=current, step=steps),
        )
      }
      None => ()
    }
    let router = runtime.graph.get_router(current)
    let route = (router.evaluate)(state, completion) catch {
      error => raise RouteFailed(node_id=current, step=steps, cause=error)
    }
    runtime.events.try_emit(RouteSelected(run_id~, from=current, route~))
    match route {
      To(target) => {
        guard is_declared_target(router.declared_targets, target) else {
          raise RouteContractViolated(from=current, to=target)
        }
        current = target
      }
      End => return RunResult::{ run_id, final_state: state, steps }
      Fail(message) => raise ExplicitFailure(node_id=current, message~)
    }
  } nobreak {
    abort("sequential runtime loop ended unexpectedly")
  }
}

///|
pub async fn[S, P] GraphRuntime::invoke(
  self : GraphRuntime[S, P],
  initial_state : S,
  options? : RunOptions = RunOptions(),
) -> RunResult[S] {
  let run_id = self.fresh_run_id()
  let stored_result : Ref[RunResult[S]?] = Ref(None)
  @async.with_task_group() <| group => {
    let resources = RuntimeResourceStore::RuntimeResourceStore()
    self.events.try_emit(RunStarted(run_id))
    let mut result : RunResult[S]? = None
    let mut primary : Error? = None
    let mut cancelled : Error? = None
    try {
      result = Some(
        run_sequential(self, initial_state, options, run_id, group, resources),
      )
    } catch {
      error if @async.is_being_cancelled() ||
        @async.is_cancellation_error(error) => cancelled = Some(error)
      error => primary = Some(error)
    }
    let cleanup = try {
      resources.finalize(options.cleanup_timeout_ms)
      None
    } catch {
      error => Some(error)
    }
    match cancelled {
      Some(error) => {
        self.events.try_emit(RunCancelled(run_id))
        raise error
      }
      None => ()
    }
    match (primary, cleanup) {
      (Some(error), Some(cleanup_error)) => {
        let failure = attach_cleanup(error, cleanup_error)
        self.events.try_emit(RunFailed(run_id~, cause=failure))
        raise failure
      }
      (Some(error), None) => {
        self.events.try_emit(RunFailed(run_id~, cause=error))
        raise error
      }
      (None, Some(cleanup_error)) => {
        let failure : Error = ResourceCleanupFailed(failure=RunFailure::{
          primary: cleanup_error,
          cleanup: [],
        })
        self.events.try_emit(RunFailed(run_id~, cause=failure))
        raise failure
      }
      (None, None) =>
        match result {
          Some(result) => {
            self.events.try_emit(RunCompleted(run_id~, steps=result.steps))
            stored_result.val = Some(result)
          }
          None => abort("run completed without result or error")
        }
    }
  }
  match stored_result.val {
    Some(result) => result
    None => abort("task group completed without run result")
  }
}
