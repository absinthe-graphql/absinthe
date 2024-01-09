defmodule Absinthe.Blueprint.Schema.EnumTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :identifier,
    :description,
    :module,
    values: [],
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
          values: [Blueprint.Schema.EnumValueDefinition.t()],
          directives: [Blueprint.Directive.t()],
          identifier: atom,
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }
  def build(type_def, _schema) do
    %Absinthe.Type.Enum{
      identifier: type_def.identifier,
      name: type_def.name,
      values: values_by(type_def, :identifier),
      values_by_internal_value: values_by(type_def, :value),
      values_by_name: values_by(type_def, :name),
      definition: type_def.module,
      description: type_def.description
    }
  end

  def values_by(type_def, key) do
    for value_def <- List.flatten(type_def.values), into: %{} do
      case value_def do
        %Blueprint.Schema.EnumValueDefinition{} ->
          value = %Absinthe.Type.Enum.Value{
            name: value_def.name,
            value: value_def.value,
            enum_identifier: type_def.identifier,
            __reference__: value_def.__reference__,
            __private__: value_def.__private__,
            description: value_def.description,
            deprecation: value_def.deprecation
          }

          {Map.fetch!(value_def, key), value}

        # Values defined via dynamic function calls don't yet get converted
        # into proper Blueprints, but it works for now. This will get refactored
        # in the future as we build out a general solution for dynamic values.
        raw_value ->
          name = raw_value |> to_string() |> String.upcase()

          value_def = %{
            name: name,
            value: raw_value,
            identifier: raw_value
          }

          value = %Absinthe.Type.Enum.Value{
            name: name,
            value: raw_value,
            enum_identifier: type_def.identifier
          }

          {Map.fetch!(value_def, key), value}
      end
    end
  end

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
