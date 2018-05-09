defmodule Absinthe.Blueprint.Schema.UnionTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    description: nil,
    directives: [],
    types: [],
    # Added by phases
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          directives: [Blueprint.Directive.t()],
          types: [Blueprint.TypeReference.Name.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, _schema) do
    %Absinthe.Type.Union{
      name: type_def.name,
      description: type_def.description,
      resolve_type: nil,
      identifier: type_def.identifier,
      types: type_def.types
    }
  end
end
