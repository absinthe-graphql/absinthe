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
    types = Map.new(schema.type_definitions, &{&1.identifier, &1})

    type_definitions =
      Enum.map(schema.type_definitions, fn type ->
        import_fields(type, types)
      end)

    {:halt, %{schema | type_definitions: type_definitions}}
  end

  def handle_imports(node), do: node

  @can_import [
    Schema.ObjectTypeDefinition,
    Schema.InputObjectTypeDefinition,
    Schema.InterfaceTypeDefinition
  ]
  @exclude_fields [
    :__typename
  ]
  # Per Absinthe.Phase.Schema.Validation.NoCircularFieldImports, there are no cycles
  # in the field imports. Therefore we can use recursion to resolve the imports.
  def import_fields(%def_type{} = type, types) when def_type in @can_import do
    Enum.reduce(type.imports, type, fn {source, opts}, type ->
      source_type =
        types
        |> Map.fetch!(source)
        |> import_fields(types)

      rejections = Keyword.get(opts, :except, []) ++ @exclude_fields

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
