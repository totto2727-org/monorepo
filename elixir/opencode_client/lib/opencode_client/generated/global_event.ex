defmodule OpencodeClient.Generated.GlobalEvent do
  @moduledoc """
  Provides struct and type for a GlobalEvent
  """

  @type t :: %__MODULE__{
          directory: String.t(),
          payload:
            OpencodeClient.Generated.EventAccountAdded.t()
            | OpencodeClient.Generated.EventAccountRemoved.t()
            | OpencodeClient.Generated.EventAccountSwitched.t()
            | OpencodeClient.Generated.EventCatalogModelUpdated.t()
            | OpencodeClient.Generated.EventCommandExecuted.t()
            | OpencodeClient.Generated.EventFileEdited.t()
            | OpencodeClient.Generated.EventFileWatcherUpdated.t()
            | OpencodeClient.Generated.EventGlobalDisposed.t()
            | OpencodeClient.Generated.EventInstallationUpdateAvailable.t()
            | OpencodeClient.Generated.EventInstallationUpdated.t()
            | OpencodeClient.Generated.EventLspClientDiagnostics.t()
            | OpencodeClient.Generated.EventLspUpdated.t()
            | OpencodeClient.Generated.EventMcpBrowserOpenFailed.t()
            | OpencodeClient.Generated.EventMcpToolsChanged.t()
            | OpencodeClient.Generated.EventMessagePartDelta.t()
            | OpencodeClient.Generated.EventMessagePartRemoved.t()
            | OpencodeClient.Generated.EventMessagePartUpdated.t()
            | OpencodeClient.Generated.EventMessageRemoved.t()
            | OpencodeClient.Generated.EventMessageUpdated.t()
            | OpencodeClient.Generated.EventModelsDevRefreshed.t()
            | OpencodeClient.Generated.EventPermissionAsked.t()
            | OpencodeClient.Generated.EventPermissionReplied.t()
            | OpencodeClient.Generated.EventPluginAdded.t()
            | OpencodeClient.Generated.EventProjectUpdated.t()
            | OpencodeClient.Generated.EventPtyCreated.t()
            | OpencodeClient.Generated.EventPtyDeleted.t()
            | OpencodeClient.Generated.EventPtyExited.t()
            | OpencodeClient.Generated.EventPtyUpdated.t()
            | OpencodeClient.Generated.EventQuestionAsked.t()
            | OpencodeClient.Generated.EventQuestionRejected.t()
            | OpencodeClient.Generated.EventQuestionReplied.t()
            | OpencodeClient.Generated.EventServerConnected.t()
            | OpencodeClient.Generated.EventServerInstanceDisposed.t()
            | OpencodeClient.Generated.EventSessionCompacted.t()
            | OpencodeClient.Generated.EventSessionCreated.t()
            | OpencodeClient.Generated.EventSessionDeleted.t()
            | OpencodeClient.Generated.EventSessionDiff.t()
            | OpencodeClient.Generated.EventSessionError.t()
            | OpencodeClient.Generated.EventSessionIdle.t()
            | OpencodeClient.Generated.EventSessionNextAgentSwitched.t()
            | OpencodeClient.Generated.EventSessionNextCompactionDelta.t()
            | OpencodeClient.Generated.EventSessionNextCompactionEnded.t()
            | OpencodeClient.Generated.EventSessionNextCompactionStarted.t()
            | OpencodeClient.Generated.EventSessionNextModelSwitched.t()
            | OpencodeClient.Generated.EventSessionNextPrompted.t()
            | OpencodeClient.Generated.EventSessionNextReasoningDelta.t()
            | OpencodeClient.Generated.EventSessionNextReasoningEnded.t()
            | OpencodeClient.Generated.EventSessionNextReasoningStarted.t()
            | OpencodeClient.Generated.EventSessionNextRetried.t()
            | OpencodeClient.Generated.EventSessionNextShellEnded.t()
            | OpencodeClient.Generated.EventSessionNextShellStarted.t()
            | OpencodeClient.Generated.EventSessionNextStepEnded.t()
            | OpencodeClient.Generated.EventSessionNextStepFailed.t()
            | OpencodeClient.Generated.EventSessionNextStepStarted.t()
            | OpencodeClient.Generated.EventSessionNextSynthetic.t()
            | OpencodeClient.Generated.EventSessionNextTextDelta.t()
            | OpencodeClient.Generated.EventSessionNextTextEnded.t()
            | OpencodeClient.Generated.EventSessionNextTextStarted.t()
            | OpencodeClient.Generated.EventSessionNextToolCalled.t()
            | OpencodeClient.Generated.EventSessionNextToolFailed.t()
            | OpencodeClient.Generated.EventSessionNextToolInputDelta.t()
            | OpencodeClient.Generated.EventSessionNextToolInputEnded.t()
            | OpencodeClient.Generated.EventSessionNextToolInputStarted.t()
            | OpencodeClient.Generated.EventSessionNextToolProgress.t()
            | OpencodeClient.Generated.EventSessionNextToolSuccess.t()
            | OpencodeClient.Generated.EventSessionStatus.t()
            | OpencodeClient.Generated.EventSessionUpdated.t()
            | OpencodeClient.Generated.EventTodoUpdated.t()
            | OpencodeClient.Generated.EventTuiCommandExecute.t()
            | OpencodeClient.Generated.EventTuiPromptAppend.t()
            | OpencodeClient.Generated.EventTuiSessionSelect.t()
            | OpencodeClient.Generated.EventTuiToastShow.t()
            | OpencodeClient.Generated.EventVcsBranchUpdated.t()
            | OpencodeClient.Generated.EventWorkspaceFailed.t()
            | OpencodeClient.Generated.EventWorkspaceReady.t()
            | OpencodeClient.Generated.EventWorkspaceStatus.t()
            | OpencodeClient.Generated.EventWorktreeFailed.t()
            | OpencodeClient.Generated.EventWorktreeReady.t()
            | OpencodeClient.Generated.SyncEventMessagePartRemoved.t()
            | OpencodeClient.Generated.SyncEventMessagePartUpdated.t()
            | OpencodeClient.Generated.SyncEventMessageRemoved.t()
            | OpencodeClient.Generated.SyncEventMessageUpdated.t()
            | OpencodeClient.Generated.SyncEventSessionCreated.t()
            | OpencodeClient.Generated.SyncEventSessionDeleted.t()
            | OpencodeClient.Generated.SyncEventSessionNextAgentSwitched.t()
            | OpencodeClient.Generated.SyncEventSessionNextCompactionDelta.t()
            | OpencodeClient.Generated.SyncEventSessionNextCompactionEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextCompactionStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextModelSwitched.t()
            | OpencodeClient.Generated.SyncEventSessionNextPrompted.t()
            | OpencodeClient.Generated.SyncEventSessionNextReasoningDelta.t()
            | OpencodeClient.Generated.SyncEventSessionNextReasoningEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextReasoningStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextRetried.t()
            | OpencodeClient.Generated.SyncEventSessionNextShellEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextShellStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextStepEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextStepFailed.t()
            | OpencodeClient.Generated.SyncEventSessionNextStepStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextSynthetic.t()
            | OpencodeClient.Generated.SyncEventSessionNextTextDelta.t()
            | OpencodeClient.Generated.SyncEventSessionNextTextEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextTextStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolCalled.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolFailed.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolInputDelta.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolInputEnded.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolInputStarted.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolProgress.t()
            | OpencodeClient.Generated.SyncEventSessionNextToolSuccess.t()
            | OpencodeClient.Generated.SyncEventSessionUpdated.t(),
          project: String.t() | nil,
          workspace: String.t() | nil
        }

  defstruct [:directory, :payload, :project, :workspace]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      directory: :string,
      payload:
        {:union,
         [
           {OpencodeClient.Generated.EventAccountAdded, :t},
           {OpencodeClient.Generated.EventAccountRemoved, :t},
           {OpencodeClient.Generated.EventAccountSwitched, :t},
           {OpencodeClient.Generated.EventCatalogModelUpdated, :t},
           {OpencodeClient.Generated.EventCommandExecuted, :t},
           {OpencodeClient.Generated.EventFileEdited, :t},
           {OpencodeClient.Generated.EventFileWatcherUpdated, :t},
           {OpencodeClient.Generated.EventGlobalDisposed, :t},
           {OpencodeClient.Generated.EventInstallationUpdateAvailable, :t},
           {OpencodeClient.Generated.EventInstallationUpdated, :t},
           {OpencodeClient.Generated.EventLspClientDiagnostics, :t},
           {OpencodeClient.Generated.EventLspUpdated, :t},
           {OpencodeClient.Generated.EventMcpBrowserOpenFailed, :t},
           {OpencodeClient.Generated.EventMcpToolsChanged, :t},
           {OpencodeClient.Generated.EventMessagePartDelta, :t},
           {OpencodeClient.Generated.EventMessagePartRemoved, :t},
           {OpencodeClient.Generated.EventMessagePartUpdated, :t},
           {OpencodeClient.Generated.EventMessageRemoved, :t},
           {OpencodeClient.Generated.EventMessageUpdated, :t},
           {OpencodeClient.Generated.EventModelsDevRefreshed, :t},
           {OpencodeClient.Generated.EventPermissionAsked, :t},
           {OpencodeClient.Generated.EventPermissionReplied, :t},
           {OpencodeClient.Generated.EventPluginAdded, :t},
           {OpencodeClient.Generated.EventProjectUpdated, :t},
           {OpencodeClient.Generated.EventPtyCreated, :t},
           {OpencodeClient.Generated.EventPtyDeleted, :t},
           {OpencodeClient.Generated.EventPtyExited, :t},
           {OpencodeClient.Generated.EventPtyUpdated, :t},
           {OpencodeClient.Generated.EventQuestionAsked, :t},
           {OpencodeClient.Generated.EventQuestionRejected, :t},
           {OpencodeClient.Generated.EventQuestionReplied, :t},
           {OpencodeClient.Generated.EventServerConnected, :t},
           {OpencodeClient.Generated.EventServerInstanceDisposed, :t},
           {OpencodeClient.Generated.EventSessionCompacted, :t},
           {OpencodeClient.Generated.EventSessionCreated, :t},
           {OpencodeClient.Generated.EventSessionDeleted, :t},
           {OpencodeClient.Generated.EventSessionDiff, :t},
           {OpencodeClient.Generated.EventSessionError, :t},
           {OpencodeClient.Generated.EventSessionIdle, :t},
           {OpencodeClient.Generated.EventSessionNextAgentSwitched, :t},
           {OpencodeClient.Generated.EventSessionNextCompactionDelta, :t},
           {OpencodeClient.Generated.EventSessionNextCompactionEnded, :t},
           {OpencodeClient.Generated.EventSessionNextCompactionStarted, :t},
           {OpencodeClient.Generated.EventSessionNextModelSwitched, :t},
           {OpencodeClient.Generated.EventSessionNextPrompted, :t},
           {OpencodeClient.Generated.EventSessionNextReasoningDelta, :t},
           {OpencodeClient.Generated.EventSessionNextReasoningEnded, :t},
           {OpencodeClient.Generated.EventSessionNextReasoningStarted, :t},
           {OpencodeClient.Generated.EventSessionNextRetried, :t},
           {OpencodeClient.Generated.EventSessionNextShellEnded, :t},
           {OpencodeClient.Generated.EventSessionNextShellStarted, :t},
           {OpencodeClient.Generated.EventSessionNextStepEnded, :t},
           {OpencodeClient.Generated.EventSessionNextStepFailed, :t},
           {OpencodeClient.Generated.EventSessionNextStepStarted, :t},
           {OpencodeClient.Generated.EventSessionNextSynthetic, :t},
           {OpencodeClient.Generated.EventSessionNextTextDelta, :t},
           {OpencodeClient.Generated.EventSessionNextTextEnded, :t},
           {OpencodeClient.Generated.EventSessionNextTextStarted, :t},
           {OpencodeClient.Generated.EventSessionNextToolCalled, :t},
           {OpencodeClient.Generated.EventSessionNextToolFailed, :t},
           {OpencodeClient.Generated.EventSessionNextToolInputDelta, :t},
           {OpencodeClient.Generated.EventSessionNextToolInputEnded, :t},
           {OpencodeClient.Generated.EventSessionNextToolInputStarted, :t},
           {OpencodeClient.Generated.EventSessionNextToolProgress, :t},
           {OpencodeClient.Generated.EventSessionNextToolSuccess, :t},
           {OpencodeClient.Generated.EventSessionStatus, :t},
           {OpencodeClient.Generated.EventSessionUpdated, :t},
           {OpencodeClient.Generated.EventTodoUpdated, :t},
           {OpencodeClient.Generated.EventTuiCommandExecute, :t},
           {OpencodeClient.Generated.EventTuiPromptAppend, :t},
           {OpencodeClient.Generated.EventTuiSessionSelect, :t},
           {OpencodeClient.Generated.EventTuiToastShow, :t},
           {OpencodeClient.Generated.EventVcsBranchUpdated, :t},
           {OpencodeClient.Generated.EventWorkspaceFailed, :t},
           {OpencodeClient.Generated.EventWorkspaceReady, :t},
           {OpencodeClient.Generated.EventWorkspaceStatus, :t},
           {OpencodeClient.Generated.EventWorktreeFailed, :t},
           {OpencodeClient.Generated.EventWorktreeReady, :t},
           {OpencodeClient.Generated.SyncEventMessagePartRemoved, :t},
           {OpencodeClient.Generated.SyncEventMessagePartUpdated, :t},
           {OpencodeClient.Generated.SyncEventMessageRemoved, :t},
           {OpencodeClient.Generated.SyncEventMessageUpdated, :t},
           {OpencodeClient.Generated.SyncEventSessionCreated, :t},
           {OpencodeClient.Generated.SyncEventSessionDeleted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextAgentSwitched, :t},
           {OpencodeClient.Generated.SyncEventSessionNextCompactionDelta, :t},
           {OpencodeClient.Generated.SyncEventSessionNextCompactionEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextCompactionStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextModelSwitched, :t},
           {OpencodeClient.Generated.SyncEventSessionNextPrompted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextReasoningDelta, :t},
           {OpencodeClient.Generated.SyncEventSessionNextReasoningEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextReasoningStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextRetried, :t},
           {OpencodeClient.Generated.SyncEventSessionNextShellEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextShellStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextStepEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextStepFailed, :t},
           {OpencodeClient.Generated.SyncEventSessionNextStepStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextSynthetic, :t},
           {OpencodeClient.Generated.SyncEventSessionNextTextDelta, :t},
           {OpencodeClient.Generated.SyncEventSessionNextTextEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextTextStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolCalled, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolFailed, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolInputDelta, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolInputEnded, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolInputStarted, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolProgress, :t},
           {OpencodeClient.Generated.SyncEventSessionNextToolSuccess, :t},
           {OpencodeClient.Generated.SyncEventSessionUpdated, :t}
         ]},
      project: :string,
      workspace: :string
    ]
  end
end
