///|
/// Distinguishes trusted deletion authority from unavailable ownership state.
pub(all) enum PreviousOwnership {
  Trusted(OwnershipState)
  Missing
  Corrupt(reason~ : String)
}

///|
/// Reports whether reconciliation reached the entire desired filesystem state.
pub(all) enum LinkReconciliationStatus {
  Complete
  Partial
} derive(Debug, Eq)

///|
/// Identifies the filesystem or durability boundary associated with a notice.
pub(all) enum LinkReconciliationOperation {
  EnsureManagedRoot
  ClassifyLink
  VerifyContainment
  CreateLink
  VerifyCreatedLink
  RemoveLink
  CheckpointOwnership
} derive(Debug, Eq)

///|
/// Describes a path that was preserved or an operation that could not complete.
pub(all) enum LinkReconciliationNotice {
  PreviousOwnershipMissing(path~ : @path.Path)
  PreviousOwnershipCorrupt(path~ : @path.Path, reason~ : String)
  UnmanagedPathPreserved(path~ : @path.Path)
  BrokenOwnedLinkPreserved(path~ : @path.Path)
  ReplacedOwnedPathPreserved(path~ : @path.Path)
  OperationFailed(
    operation~ : LinkReconciliationOperation,
    path~ : @path.Path,
    reason~ : String
  )
  CheckpointFailed(
    operation~ : LinkReconciliationOperation,
    path~ : @path.Path,
    reason~ : String
  )
}

///|
/// Returns the last durably checkpointed ownership state and typed notices.
pub struct LinkReconciliationResult {
  status : LinkReconciliationStatus
  durable_state : OwnershipState
  notices : ReadOnlyArray[LinkReconciliationNotice]
}

///|
async fn reconcile_skill_links_with_io(
  io : LinkReconciliationIO,
  state_path : @path.Path,
  desired_state : OwnershipState,
  previous_ownership : PreviousOwnership,
) -> LinkReconciliationResult {
  let (initial_state, initial_notices) = match previous_ownership {
    Trusted(state) => (state, [])
    Missing =>
      (
        try! OwnershipState::OwnershipState([]),
        [PreviousOwnershipMissing(path=state_path)],
      )
    Corrupt(reason~) =>
      (
        try! OwnershipState::OwnershipState([]),
        [PreviousOwnershipCorrupt(path=state_path, reason~)],
      )
  }
  let mut durable_state = initial_state
  let notices = initial_notices
  let clean_stale_entries = match previous_ownership {
    Trusted(_) => true
    Missing | Corrupt(_) => false
  }
  let (desired_durable_state, desired_hard_stop) = reconcile_desired_entries(
    io~,
    state_path~,
    desired_state~,
    durable_state~,
    notices~,
  )
  match desired_hard_stop {
    Some(result) => return result
    None => durable_state = desired_durable_state
  }
  if clean_stale_entries {
    let (stale_durable_state, stale_hard_stop) = reconcile_stale_entries(
      io~,
      state_path~,
      desired_state~,
      durable_state~,
      notices~,
    )
    match stale_hard_stop {
      Some(result) => return result
      None => durable_state = stale_durable_state
    }
  }
  {
    status: if notices.is_empty() {
      Complete
    } else {
      Partial
    },
    durable_state,
    notices: ReadOnlyArray::from_array(notices),
  }
}

///|
/// Reconciles desired skill links and checkpoints each ownership mutation.
///
/// The caller must pass a normalized absolute state path and an atomic checkpoint
/// callback. Repository resolution and ownership-state loading remain outside this
/// filesystem boundary.
pub async fn reconcile_skill_links(
  state_path~ : @path.Path,
  desired_state~ : OwnershipState,
  previous_ownership~ : PreviousOwnership,
  checkpoint_ownership_state~ : async (@path.Path, OwnershipState) -> Unit raise StateStoreError,
) -> LinkReconciliationResult {
  guard state_path.is_absolute() && state_path.normalize() == state_path else {
    fail("ownership state path must be normalized and absolute")
  }
  reconcile_skill_links_with_io(
    production_link_reconciliation_io(checkpoint_ownership_state),
    state_path,
    desired_state,
    previous_ownership,
  )
}
