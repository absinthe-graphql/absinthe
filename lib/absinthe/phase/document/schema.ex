defmodule Absinthe.Phase.Document.Schema do
  use Absinthe.Phase

  alias Absinthe.{Blueprint, Type}

  @spec run(Blueprint.t, Absinthe.Schema.t) :: {:ok, Blueprint.t}
  def run(input, schema) do
    do_run(input, %{schema: schema, adapter: Absinthe.Adapter.LanguageConventions})
  end

  def do_run(input, %{schema: schema, adapter: adapter}) do
    {result, _} = Blueprint.prewalk(input, %{adapter: adapter}, &handle_node(&1, schema, &2))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t, Absinthe.Schema.t, map) :: Blueprint.node_t
  defp handle_node(%Blueprint{} = node, schema, acc) do
    {put_in(node.schema, schema), acc}
  end
  defp handle_node(%Blueprint.Document.Fragment.Named{} = node, schema, acc) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, acc.adapter))
    {
      %{node | schema_node: schema_node, selections: selections_with_schema},
      acc
    }
  end
  defp handle_node(%Blueprint.Document.Fragment.Inline{} = node, schema, acc) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, acc.adapter))
    {
      %{node | schema_node: schema_node, selections: selections_with_schema},
      acc
    }
  end
  defp handle_node(%Blueprint.Directive{name: name} = node, schema, acc) do
    {
      put_in(node.schema_node, schema.__absinthe_directive__(name)),
      acc
    }
  end
  defp handle_node(%Blueprint.Document.Operation{type: op_type} = node, schema, acc) do
    schema_node = schema.__absinthe_type__(op_type)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, acc.adapter))
    {
      %{node | schema_node: schema_node, selections: selections_with_schema},
      acc
    }
  end
  defp handle_node(node, _, acc) do
    {node, acc}
  end

  @spec selection_with_schema_node(Blueprint.Document.selection_t, Type.t, Absinthe.Adapter.t) :: Type.t
  def selection_with_schema_node(%Blueprint.Document.Field{} = node, parent_schema_node, adapter) do
    schema_node = find_schema_field(parent_schema_node, node.name, adapter)
    put_in(node.schema_node, schema_node)
  end

  @spec find_schema_field(nil | Type.t, String.t, Absinthe.Adapter.t) :: Type.Field.t
  defp find_schema_field(%{fields: fields}, name, adapter) do
    internal_name = adapter.to_internal_name(name, :field)
    fields
    |> Map.values
    |> Enum.find(fn
      %{name: ^internal_name} ->
       true
      _ ->
        false
    end)
  end
  defp find_schema_field(_, _, _) do
    nil
  end

end
