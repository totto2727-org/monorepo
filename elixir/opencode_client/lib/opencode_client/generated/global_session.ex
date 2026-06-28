defmodule OpencodeClient.Generated.GlobalSession do
  @moduledoc """
  Provides struct and type for a GlobalSession
  """

  @type t :: %__MODULE__{
          agent: String.t() | nil,
          cost: number | nil,
          directory: String.t(),
          id: String.t(),
          metadata: map | nil,
          model: OpencodeClient.Generated.GlobalSessionModel.t() | nil,
          parentID: String.t() | nil,
          path: String.t() | nil,
          permission: [OpencodeClient.Generated.PermissionRule.t()] | nil,
          project: OpencodeClient.Generated.ProjectSummary.t() | nil,
          projectID: String.t(),
          revert: OpencodeClient.Generated.GlobalSessionRevert.t() | nil,
          share: OpencodeClient.Generated.GlobalSessionShare.t() | nil,
          slug: String.t(),
          summary: OpencodeClient.Generated.GlobalSessionSummary.t() | nil,
          time: OpencodeClient.Generated.GlobalSessionTime.t(),
          title: String.t(),
          tokens: OpencodeClient.Generated.GlobalSessionTokens.t() | nil,
          version: String.t(),
          workspaceID: String.t() | nil
        }

  defstruct [
    :agent,
    :cost,
    :directory,
    :id,
    :metadata,
    :model,
    :parentID,
    :path,
    :permission,
    :project,
    :projectID,
    :revert,
    :share,
    :slug,
    :summary,
    :time,
    :title,
    :tokens,
    :version,
    :workspaceID
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      cost: :number,
      directory: :string,
      id: :string,
      metadata: :map,
      model: {OpencodeClient.Generated.GlobalSessionModel, :t},
      parentID: :string,
      path: :string,
      permission: [{OpencodeClient.Generated.PermissionRule, :t}],
      project: {:union, [{OpencodeClient.Generated.ProjectSummary, :t}, :null]},
      projectID: :string,
      revert: {OpencodeClient.Generated.GlobalSessionRevert, :t},
      share: {OpencodeClient.Generated.GlobalSessionShare, :t},
      slug: :string,
      summary: {OpencodeClient.Generated.GlobalSessionSummary, :t},
      time: {OpencodeClient.Generated.GlobalSessionTime, :t},
      title: :string,
      tokens: {OpencodeClient.Generated.GlobalSessionTokens, :t},
      version: :string,
      workspaceID: :string
    ]
  end
end
