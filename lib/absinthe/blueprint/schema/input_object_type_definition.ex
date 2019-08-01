defmodule Absinthe.Blueprint.Schema.InputObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    fields: [],
    imports: [],
    directives: [],
    source_location: nil,
    # Added by phases,
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          fields: [Blueprint.Schema.InputValueDefinition.t()],
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Type.InputObject{
      identifier: type_def.identifier,
      name: type_def.name,
      fields: build_fields(type_def, schema),
      description: type_def.description,
      definition: type_def.module
    }
  end

  def build_fields(type_def, schema) do
    for field_def <- type_def.fields, into: %{} do
      field = %Type.Field{
        identifier: field_def.identifier,
        deprecation: field_def.deprecation,
        description: field_def.description,
        name: field_def.name,
        type: Blueprint.TypeReference.to_type(field_def.type, schema),
        definition: type_def.module,
        __reference__: field_def.__reference__,
        __private__: field_def.__private__,
        default_value: field_def.default_value
      }

      {field.identifier, field}
    end
  end

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
