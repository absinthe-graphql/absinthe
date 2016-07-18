defmodule Absinthe.Phase.Document.Schema do
  use Absinthe.Phase

  alias Absinthe.{Blueprint, Type}

  @spec run(Blueprint.t, Absinthe.Schema.t) :: {:ok, Blueprint.t}
  def run(input, schema) do
    do_run(input, %{schema: schema, adapter: Absinthe.Adapter.LanguageConventions})
  end

  defp do_run(input, %{schema: schema, adapter: adapter}) do
    result = Blueprint.prewalk(input, &handle_node(&1, schema, adapter))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Blueprint.node_t
  defp handle_node(%Blueprint{} = node, schema, _) do
    %{node | schema: schema}
  end
  defp handle_node(%Blueprint.Document.Fragment.Named{} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &field_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(%Blueprint.Document.Fragment.Inline{} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &field_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(%Blueprint.Directive{name: name} = node, schema, adapter) do
    schema_node = schema.__absinthe_directive__(name)
    arguments = Enum.map(node.arguments, &argument_with_schema_node(&1, schema_node, adapter))
    %{node | schema_node: schema_node, arguments: arguments}
  end
  defp handle_node(%Blueprint.Document.Operation{type: op_type} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(op_type)
    selections_with_schema = Enum.map(node.selections, &field_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(node, _, _) do
    node
  end

  # Given a blueprint field node, fill in its schema node
  #
  # (If it's a fragment spread or inline fragment, we skip it, as the
  # appropriate `handle_node` for the fragment type will call this itself.)
  @spec field_with_schema_node(Blueprint.Document.selection_t, Type.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Type.t
  defp field_with_schema_node(%Blueprint.Document.Field{} = node, parent_schema_node, schema, adapter) do
    schema_node = find_schema_field(parent_schema_node, node.name, schema, adapter)
    selections = Enum.map(node.selections, &field_with_schema_node(&1, schema_node, schema, adapter))
    arguments = Enum.map(node.arguments, &argument_with_schema_node(&1, schema_node, adapter))
    %{node | schema_node: schema_node, selections: selections, arguments: arguments}
  end
  defp field_with_schema_node(node, _, _, _) do
    node
  end

  # Given a schema type, lookup a child field definition
  @spec find_schema_field(nil | Type.t, String.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: nil | Type.Field.t
  defp find_schema_field(%{fields: fields}, name, _, adapter) do
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
  defp find_schema_field(%Type.Field{type: maybe_wrapped_type}, name, schema, adapter) do
    type = Type.unwrap(maybe_wrapped_type)
    |> schema.__absinthe_type__
    find_schema_field(type, name, schema, adapter)
  end
  defp find_schema_field(_, _, _, _) do
    nil
  end

  # Given a blueprint argument node, fill in its schema node
  @spec argument_with_schema_node(Blueprint.Input.Argument.t, nil, Absinthe.Adapter.t) :: Type.t
  defp argument_with_schema_node(%{name: name} = node, parent_schema_node, adapter) do
    schema_node = find_schema_argument(parent_schema_node, name, adapter)
    %{node | schema_node: schema_node}
  end
  defp argument_with_schema_node(node, nil, _) do
    node
  end

  # Given a schema field or directive, lookup a child argument definition
  @spec find_schema_argument(nil | Type.Field.t | Type.Argument.t, String.t, Absinthe.Adapter.t) :: nil | Type.Argument.t
  defp find_schema_argument(%{args: arguments}, name, adapter) do
    internal_name = adapter.to_internal_name(name, :argument)
    arguments
    |> Map.values
    |> Enum.find(fn
      %{name: ^internal_name} ->
        true
      _ ->
        false
    end)
  end
  defp find_schema_argument(nil, _, _) do
    nil
  end

end
