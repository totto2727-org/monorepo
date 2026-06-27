defmodule OpencodeClient.Generated.SessionMessageModelSwitched do
  @moduledoc """
  Provides struct and type for a SessionMessageModelSwitched
  """

  @type t :: %__MODULE__{
          id: String.t(),
          metadata: map | nil,
          model: OpencodeClient.Generated.SessionMessageModelSwitchedModel.t(),
          time: OpencodeClient.Generated.SessionMessageModelSwitchedTime.t(),
          type: String.t()
        }

  defstruct [:id, :metadata, :model, :time, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      metadata: :map,
      model: {OpencodeClient.Generated.SessionMessageModelSwitchedModel, :t},
      time: {OpencodeClient.Generated.SessionMessageModelSwitchedTime, :t},
      type: {:const, "model-switched"}
    ]
  end
end
