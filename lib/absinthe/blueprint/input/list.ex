defmodule Absinthe.Blueprint.Input.List do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:values]
  defstruct [
    :values,
    :source_location,
    # Added by phases
    flags: [],
    schema_node: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    values: [Blueprint.Input.t],
    flags: [],
    schema_node: nil | Absinthe.Type.t,
    source_location: Blueprint.Document.SourceLocation.t,
    errors: [Phase.Error.t],
  }

  @doc """
  Wrap another input node in a list.
  """
  @spec wrap(Blueprint.Input.t) :: t
  def wrap(%str{} = node) when str != __MODULE__ do
    %__MODULE__{values: [node]}
  end
  def wrap(node) do
    node
  end
end
