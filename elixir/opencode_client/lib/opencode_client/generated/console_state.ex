defmodule OpencodeClient.Generated.ConsoleState do
  @moduledoc """
  Provides struct and type for a ConsoleState
  """

  @type t :: %__MODULE__{
          activeOrgName: String.t() | nil,
          consoleManagedProviders: [String.t()],
          switchableOrgCount: integer
        }

  defstruct [:activeOrgName, :consoleManagedProviders, :switchableOrgCount]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [activeOrgName: :string, consoleManagedProviders: [:string], switchableOrgCount: :integer]
  end
end
