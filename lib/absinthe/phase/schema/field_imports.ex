defmodule Absinthe.Phase.Schema.FieldImports do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &handle_imports/1)
    {:ok, blueprint}
  end

  def handle_imports(%Schema.SchemaDefinition{} = schema) do
    # Per Phase.Schema.ValidateTypeReferences, the types are already
    # in the order they need to be in to accumulate imports properly.
    types =
      Enum.reduce(schema.type_definitions, %{}, fn type, types ->
        Map.put(types, type.identifier, import_fields(type, types))
      end)

    types = Enum.map(schema.type_definitions, &Map.fetch!(types, &1.identifier))
    {:halt, %{schema | type_definitions: types}}
  end

  def handle_imports(node), do: node

  @can_import [
    Schema.ObjectTypeDefinition,
    Schema.InputObjectTypeDefinition,
    Schema.InterfaceTypeDefinition
  ]
  def import_fields(%def_type{} = type, types) when def_type in @can_import do
    Enum.reduce(type.imports, type, fn {source, opts}, type ->
      source_type = Map.fetch!(types, source)

      rejections = Keyword.get(opts, :except, [])

      fields = source_type.fields |> Enum.reject(&(&1.identifier in rejections))

      fields =
        case Keyword.fetch(opts, :only) do
          {:ok, selections} ->
            Enum.filter(fields, &(&1.identifier in selections))

          _ ->
            fields
        end

      %{type | fields: fields ++ type.fields}
    end)
  end

  def import_fields(type, _), do: type
end
