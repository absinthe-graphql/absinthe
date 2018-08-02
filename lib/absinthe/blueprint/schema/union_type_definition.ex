defmodule Absinthe.Blueprint.Schema.UnionTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    resolve_type: nil,
    directives: [],
    types: [],
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil
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

  def build(type_def, schema) do
    %Absinthe.Type.Union{
      name: type_def.name,
      description: type_def.description,
      identifier: type_def.identifier,
      types: type_def.types
    }
  end
end
