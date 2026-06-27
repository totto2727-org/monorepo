defmodule OpencodeClient.Generated.SyncEventSessionUpdatedDataInfo do
  @moduledoc """
  Provides struct and type for a SyncEventSessionUpdatedDataInfo
  """

  @type t :: %__MODULE__{
          agent: String.t() | nil,
          cost: number | nil,
          directory: String.t() | nil,
          id: String.t() | nil,
          metadata: map | nil,
          model: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoModel.t() | nil,
          parentID: String.t() | nil,
          path: String.t() | nil,
          permission: [OpencodeClient.Generated.PermissionRule.t()] | nil,
          projectID: String.t() | nil,
          revert: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoRevert.t() | nil,
          share: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoShare.t() | nil,
          slug: String.t() | nil,
          summary: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoSummary.t() | nil,
          time: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoTime.t() | nil,
          title: String.t() | nil,
          tokens: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoTokens.t() | nil,
          version: String.t() | nil,
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
      agent: {:union, [:string, :null]},
      cost: {:union, [:number, :null]},
      directory: {:union, [:string, :null]},
      id: {:union, [:string, :null]},
      metadata: {:union, [:map, :null]},
      model:
        {:union, [{OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoModel, :t}, :null]},
      parentID: {:union, [:string, :null]},
      path: {:union, [:string, :null]},
      permission: {:union, [[{OpencodeClient.Generated.PermissionRule, :t}], :null]},
      projectID: {:union, [:string, :null]},
      revert:
        {:union, [{OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoRevert, :t}, :null]},
      share: {OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoShare, :t},
      slug: {:union, [:string, :null]},
      summary:
        {:union, [{OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoSummary, :t}, :null]},
      time: {OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoTime, :t},
      title: {:union, [:string, :null]},
      tokens:
        {:union, [{OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoTokens, :t}, :null]},
      version: {:union, [:string, :null]},
      workspaceID: {:union, [:string, :null]}
    ]
  end
end
