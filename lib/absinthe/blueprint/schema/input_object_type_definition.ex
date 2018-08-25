defmodule Absinthe.Blueprint.Schema.InputObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    interfaces: [],
    fields: [],
    imports: [],
    directives: [],
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
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, _schema) do
    %Type.InputObject{
      identifier: type_def.identifier,
      name: type_def.name,
      fields: build_fields(type_def),
      description: type_def.description,
      definition: type_def.module
    }
  end

  def build_fields(type_def) do
    for field_def <- type_def.fields, into: %{} do
      field = %Type.Field{
        identifier: field_def.identifier,
        deprecation: field_def.deprecation,
        description: field_def.description,
        name: field_def.name,
        type: field_def.type,
        definition: type_def.module,
        __reference__: field_def.__reference__,
        __private__: field_def.__private__,
        default_value: field_def.default_value
      }

      {field.identifier, field}
    end
  end
end
