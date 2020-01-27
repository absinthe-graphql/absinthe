defmodule Absinthe.Phase.Schema.MarkReferenced do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint.{Schema, TypeReference}

  def run(blueprint, _opts) do
    %{schema_definitions: [schema]} = blueprint

    schema =
      Map.update!(schema, :type_definitions, &mark_referenced(&1, schema.directive_definitions))

    {:ok, %{blueprint | schema_definitions: [schema]}}
  end

  @roots [:query, :mutation, :subscription]
  defp mark_referenced(type_defs, directive_defs) do
    types_by_ref =
      Enum.reduce(type_defs, %{}, fn type_def, acc ->
        acc
        |> Map.put(type_def.identifier, type_def)
        |> Map.put(type_def.name, type_def)
      end)

    referenced_type_ids =
      @roots
      |> Enum.map(&Map.get(types_by_ref, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.concat(directive_defs)
      |> Enum.reduce(MapSet.new(), &referenced_types(&1, types_by_ref, &2))

    for type <- type_defs do
      if type.identifier in referenced_type_ids do
        put_in(type.__private__[:__absinthe_referenced__], true)
      else
        type
      end
    end
  end

  defp referenced_types(%Schema.InputValueDefinition{type: type}, types, acc) do
    referenced_types(type, types, acc)
  end

  defp referenced_types(%Schema.DirectiveDefinition{} = type, types, acc) do
    type.arguments
    |> Enum.reduce(acc, &referenced_types(&1, types, &2))
  end

  defp referenced_types(%Schema.EnumTypeDefinition{identifier: identifier}, _types, acc) do
    MapSet.put(acc, identifier)
  end

  defp referenced_types(%Schema.FieldDefinition{} = field, types, acc) do
    acc =
      field.arguments
      |> Enum.reduce(acc, &referenced_types(&1, types, &2))

    referenced_types(field.type, types, acc)
  end

  defp referenced_types(
         %Schema.InputObjectTypeDefinition{identifier: identifier} = input_object,
         types,
         acc
       ) do
    if identifier in acc do
      acc
    else
      acc = MapSet.put(acc, identifier)

      input_object.fields
      |> Enum.reduce(acc, &referenced_types(&1, types, &2))
    end
  end

  defp referenced_types(
         %Schema.InterfaceTypeDefinition{identifier: identifier} = interface,
         schema,
         acc
       ) do
    if identifier in acc do
      acc
    else
      acc = MapSet.put(acc, identifier)

      acc =
        interface
        |> Schema.InterfaceTypeDefinition.find_implementors(Map.values(schema))
        |> Enum.reduce(acc, &referenced_types(&1, schema, &2))

      interface.fields
      |> Enum.reduce(acc, &referenced_types(&1, schema, &2))
    end
  end

  defp referenced_types(%TypeReference.List{of_type: inner_type}, schema, acc) do
    referenced_types(inner_type, schema, acc)
  end

  defp referenced_types(%TypeReference.NonNull{of_type: inner_type}, schema, acc) do
    referenced_types(inner_type, schema, acc)
  end

  defp referenced_types(
         %Schema.ObjectTypeDefinition{identifier: identifier} = object,
         schema,
         acc
       ) do
    if identifier in acc do
      acc
    else
      acc = MapSet.put(acc, identifier)

      acc =
        object.fields
        |> Enum.reduce(acc, &referenced_types(&1, schema, &2))

      object.interfaces
      |> Enum.reduce(acc, &referenced_types(&1, schema, &2))
    end
  end

  defp referenced_types(%Schema.ScalarTypeDefinition{identifier: identifier}, _schema, acc) do
    MapSet.put(acc, identifier)
  end

  defp referenced_types(%Schema.UnionTypeDefinition{identifier: identifier} = union, schema, acc) do
    if identifier in acc do
      acc
    else
      acc = MapSet.put(acc, identifier)

      union.types
      |> Enum.reduce(acc, &referenced_types(&1, schema, &2))
    end
  end

  defp referenced_types(%TypeReference.Identifier{} = ref, schema, acc) do
    referenced_types(Map.fetch!(schema, ref.id), schema, acc)
  end

  defp referenced_types(%TypeReference.Name{} = ref, schema, acc) do
    referenced_types(Map.fetch!(schema, ref.name), schema, acc)
  end

  defp referenced_types(type, schema, acc) when is_atom(type) and type != nil do
    referenced_types(Map.fetch!(schema, type), schema, acc)
  end
end
