defmodule OpencodeClient.Generated.SessionInfo do
  @moduledoc """
  Provides struct and type for a SessionInfo
  """

  @type t :: %__MODULE__{
          agent: String.t() | nil,
          cost: number,
          id: String.t(),
          model: OpencodeClient.Generated.SessionInfoModel.t() | nil,
          parentID: String.t() | nil,
          path: String.t() | nil,
          projectID: String.t(),
          time: OpencodeClient.Generated.SessionInfoTime.t(),
          title: String.t(),
          tokens: OpencodeClient.Generated.SessionInfoTokens.t(),
          workspaceID: String.t() | nil
        }

  defstruct [
    :agent,
    :cost,
    :id,
    :model,
    :parentID,
    :path,
    :projectID,
    :time,
    :title,
    :tokens,
    :workspaceID
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      cost: :number,
      id: :string,
      model: {OpencodeClient.Generated.SessionInfoModel, :t},
      parentID: :string,
      path: :string,
      projectID: :string,
      time: {OpencodeClient.Generated.SessionInfoTime, :t},
      title: :string,
      tokens: {OpencodeClient.Generated.SessionInfoTokens, :t},
      workspaceID: :string
    ]
  end
end
