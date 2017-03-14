defmodule Absinthe.Phase.Document.ExpandSchemaReferences do
  @moduledoc false

  # This module ensures that all schema lookups necessary for resolution have
  # already been run.

  alias Absinthe.{Blueprint, Type}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    {result, types_referenced_by_abstract_types} = Blueprint.prewalk(input, MapSet.new, &handle_node(&1, &2, input.schema))

    type_cache = build_type_cache(types_referenced_by_abstract_types, input.schema)

    resolution = %{result.resolution | type_cache: type_cache}

    {:ok, %{result | resolution: resolution}}
  end

  def handle_node(node, used_abstract_types, schema) do
    node =
      node
      |> expand_schema_node(schema)
      |> expand_type_conditions(schema)
      |> ensure_child_types

    used_abstract_types = check_abstract_type_usage(node, schema, used_abstract_types)

    {node, used_abstract_types}
  end

  defp ensure_child_types(%{fields: []} = node), do: node
  defp ensure_child_types(%{fields: fields, schema_node: %{type: %Type.Object{fields: schema_fields}}} = node) do
    fields = for field <- fields do
      case field.name do
        "__" <> _ ->
          field
        _ ->
          %{field | schema_node: Map.fetch!(schema_fields, field.schema_node.__reference__.identifier), type_conditions: []}
      end
    end
    %{node | fields: fields}
  end
  defp ensure_child_types(node), do: node

  defp expand_schema_node(%{schema_node: schema_node} = node, schema) do
    %{node | schema_node: expand(schema_node, schema)}
  end
  defp expand_schema_node(node, _schema) do
    node
  end

  defp expand_type_conditions(%{type_conditions: []} = node, _schema) do
    node
  end
  defp expand_type_conditions(%{type_conditions: conditions} = node, schema) do
    conditions = for %{name: name} <- conditions do
      # we can use __absinthe_type__ here instead of the __absinthe_lookup__
      # because we don't need to load the middleware on this type. Type conditions
      # don't use the middleware stuff.
      schema.__absinthe_type__(name)
    end
    %{node | type_conditions: conditions}
  end
  defp expand_type_conditions(node, _schema) do
    node
  end

  defp check_abstract_type_usage(%{schema_node: schema_node}, schema, types) do
    collate_used(schema_node, schema, types)
  end
  defp check_abstract_type_usage(_node, _schema, types) do
    types
  end

  defp collate_used(%{type: type}, schema, types) do
    collate_used(type, schema, types)
  end
  defp collate_used(%{of_type: type}, schema, types) do
    collate_used(type, schema, types)
  end
  defp collate_used(%Type.Interface{__reference__: %{identifier: identifier}}, schema, types) do
    schema.__absinthe_interface_implementors__
    |> Map.fetch!(identifier)
    |> Enum.into(types)
  end
  defp collate_used(%Type.Union{} = union, _schema, types) do
    union.types
    |> Enum.into(types)
  end
  defp collate_used(_type, _schema, types) do
    types
  end

  defp expand(nil, _schema) do
    nil
  end
  defp expand(%{type: type} = node, schema) do
    %{node | type: expand(type, schema)}
  end
  defp expand(%{of_type: type} = node, schema) do
    %{node | of_type: expand(type, schema)}
  end
  defp expand(type, schema) when is_atom(type) do
    schema
    |> Absinthe.Schema.lookup_type(type)
    |> expand(schema)
  end
  defp expand(type, _) do
    type
  end

  defp build_type_cache(types, schema) do
    Map.new(types, fn type_identifier ->
      type =
        schema
        |> Absinthe.Schema.lookup_type(type_identifier)
        |> Map.update!(:fields, fn fields ->
          Map.new(fields, fn {field_name, field} ->
            {field_name, expand(field, schema)}
          end)
        end)

      {type_identifier, type}
    end)
  end
end
