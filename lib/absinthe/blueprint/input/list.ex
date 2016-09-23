defmodule Absinthe.Blueprint.Input.List do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:items]
  defstruct [
    :items,
    :source_location,
    # Added by phases
    flags: %{},
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    items: [Blueprint.Input.List.Item.t],
    flags: Blueprint.flags_t,
    schema_node: nil | Absinthe.Type.t,
    source_location: Blueprint.Document.SourceLocation.t,
    errors: [Phase.Error.t],
  }

  @doc """
  Wrap another input node in a list.
  """
  @spec wrap(Blueprint.Input.t) :: t
  def wrap(%__MODULE__{} = list), do: list
  def wrap(node) do
    %__MODULE__{items: [node], source_location: node.source_location}
  end
end
