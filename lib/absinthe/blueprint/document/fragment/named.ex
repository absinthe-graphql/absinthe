defmodule Absinthe.Blueprint.Document.Fragment.Named do
  @moduledoc false

  alias Absinthe.Blueprint
  alias __MODULE__

  @enforce_keys [:name, :type_condition]
  defstruct [
    :name,
    :type_condition,
    selections: [],
    directives: [],
    source_location: nil,
    # Populated by phases
    schema_node: nil,
    complexity: nil,
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          directives: [Blueprint.Directive.t()],
          errors: [Absinthe.Phase.Error.t()],
          name: String.t(),
          selections: [Blueprint.Document.selection_t()],
          schema_node: nil | Absinthe.Type.t(),
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          flags: Blueprint.flags_t(),
          type_condition: Blueprint.TypeReference.Name.t()
        }

  @doc """
  Generate a use reference for a fragment.
  """
  @spec to_use(t) :: Named.Use.t()
  def to_use(%__MODULE__{} = node) do
    %Named.Use{
      name: node.name,
      source_location: node.source_location
    }
  end
end
