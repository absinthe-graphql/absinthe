defmodule Absinthe.Phase.Document.ExpandSchemaReferences do
  @moduledoc false

  # This module ensures that all schema lookups necessary for resolution have
  # already been run.

  alias Absinthe.{Blueprint}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  def handle_node(node, schema) do
    node
    |> expand_schema_node(schema)
    |> expand_type_conditions(schema)
  end

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
end
