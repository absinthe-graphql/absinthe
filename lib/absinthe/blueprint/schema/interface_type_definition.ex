defmodule Absinthe.Blueprint.Schema.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

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
    referenced: false,
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
          referenced: boolean,
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
      referenced: type_def.referenced,
      definition: type_def.module
    }
  end

  def find_implementors(iface, type_defs) do
    for %Schema.ObjectTypeDefinition{} = obj <- type_defs,
        iface.identifier in obj.interfaces,
        do: obj.identifier
  end

  @doc false
  def functions(), do: [:resolve_type]

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
