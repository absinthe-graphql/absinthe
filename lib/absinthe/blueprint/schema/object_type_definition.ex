defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name]
  defstruct [
    :name,
    :identifier,
    :module,
    description: nil,
    interfaces: [],
    interface_blueprints: [],
    fields: [],
    directives: [],
    is_type_of: nil,
    source_location: nil,
    # Added by phases
    flags: %{},
    imports: [],
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          interfaces: [String.t()],
          interface_blueprints: [Blueprint.Draft.t()],
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()],
          __private__: Keyword.t()
        }

  @doc false
  def functions(), do: [:is_type_of]

  def build(type_def, schema) do
    %Type.Object{
      identifier: type_def.identifier,
      name: type_def.name,
      description: type_def.description,
      fields: build_fields(type_def, schema),
      interfaces: type_def.interfaces,
      definition: type_def.module,
      is_type_of: type_def.is_type_of,
      __private__: type_def.__private__
    }
  end

  def build_fields(type_def, schema) do
    for field_def <- type_def.fields, into: %{} do
      field = %Type.Field{
        identifier: field_def.identifier,
        middleware: field_def.middleware,
        deprecation: field_def.deprecation,
        description: field_def.description,
        complexity: field_def.complexity,
        config: field_def.complexity,
        triggers: field_def.triggers,
        name: field_def.name,
        type: Blueprint.TypeReference.to_type(field_def.type, schema),
        args: build_args(field_def, schema),
        definition: field_def.module,
        __reference__: field_def.__reference__,
        __private__: field_def.__private__
      }

      {field.identifier, field}
    end
  end

  def build_args(field_def, schema) do
    Map.new(field_def.arguments, fn arg_def ->
      arg = %Type.Argument{
        identifier: arg_def.identifier,
        name: arg_def.name,
        description: arg_def.description,
        type: Blueprint.TypeReference.to_type(arg_def.type, schema),
        default_value: arg_def.default_value,
        deprecation: arg_def.deprecation
      }

      {arg_def.identifier, arg}
    end)
  end

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
