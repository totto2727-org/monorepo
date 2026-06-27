defmodule OpencodeClient.Generated.Event do
  @moduledoc """
  Provides API endpoint related to event
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  Subscribe to events

  Get events

  ## Options

    * `directory`
    * `workspace`

  """
  @spec event_subscribe(opts :: keyword) ::
          {:ok,
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
           | OpencodeClient.Generated.EventTuiToastShow1.t()
           | OpencodeClient.Generated.EventVcsBranchUpdated.t()
           | OpencodeClient.Generated.EventWorkspaceFailed.t()
           | OpencodeClient.Generated.EventWorkspaceReady.t()
           | OpencodeClient.Generated.EventWorkspaceStatus.t()
           | OpencodeClient.Generated.EventWorktreeFailed.t()
           | OpencodeClient.Generated.EventWorktreeReady.t()}
          | :error
  def event_subscribe(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Event, :event_subscribe},
      url: "/event",
      method: :get,
      query: query,
      response: [
        {200,
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
            {OpencodeClient.Generated.EventTuiToastShow1, :t},
            {OpencodeClient.Generated.EventVcsBranchUpdated, :t},
            {OpencodeClient.Generated.EventWorkspaceFailed, :t},
            {OpencodeClient.Generated.EventWorkspaceReady, :t},
            {OpencodeClient.Generated.EventWorkspaceStatus, :t},
            {OpencodeClient.Generated.EventWorktreeFailed, :t},
            {OpencodeClient.Generated.EventWorktreeReady, :t}
          ]}}
      ],
      opts: opts
    })
  end
end
