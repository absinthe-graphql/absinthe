defmodule Absinthe.Blueprint.Schema.UnionTypeDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @enforce_keys [:name]
  defstruct [
    :identifier,
    :name,
    :module,
    description: nil,
    resolve_type: nil,
    fields: [],
    directives: [],
    types: [],
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          directives: [Blueprint.Directive.t()],
          types: [Blueprint.TypeReference.Name.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Type.Union{
      name: type_def.name,
      description: type_def.description,
      identifier: type_def.identifier,
      types: type_def.types |> atomize_types(schema),
      fields: build_fields(type_def, schema),
      definition: type_def.module,
      resolve_type: type_def.resolve_type
    }
  end

  defp atomize_types(types, schema) do
    types
    |> Enum.map(&Blueprint.TypeReference.to_type(&1, schema))
    |> Enum.sort()
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

  @doc false
  def functions(), do: [:resolve_type]

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
