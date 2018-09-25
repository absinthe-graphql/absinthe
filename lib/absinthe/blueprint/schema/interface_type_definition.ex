defmodule Absinthe.Blueprint.Schema.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    fields: [],
    directives: [],
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: [],
    resolve_type: nil,
    imports: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Absinthe.Type.Interface{
      name: type_def.name,
      description: type_def.description,
      fields: Blueprint.Schema.ObjectTypeDefinition.build_fields(type_def, schema),
      identifier: type_def.identifier,
      resolve_type: type_def.resolve_type,
      definition: type_def.module
    }
  end

  @doc false
  def functions(), do: [:resolve_type]
end
