defmodule Absinthe.Phase.Schema do
  @moduledoc """
  Populate all schema nodes and the adapter for the blueprint tree. If the
  blueprint tree is a _schema_ tree, this schema is the meta schema (source of
  IDL directives, etc).

  Note that no validation occurs in this phase.
  """
  use Absinthe.Phase

  alias Absinthe.{Blueprint, Type, Schema}

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, options \\ []) do
    schema = Keyword.fetch!(options, :schema)
    adapter = Keyword.get(options, :adapter, Absinthe.Adapter.LanguageConventions)
    do_run(input, %{schema: schema, adapter: adapter})
  end

  defp do_run(input, %{schema: schema, adapter: adapter}) do
    result = Blueprint.prewalk(input, &handle_node(&1, schema, adapter))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Blueprint.node_t
  defp handle_node(%Blueprint{} = node, schema, adapter) do
    %{node | schema: schema, adapter: adapter}
  end
  defp handle_node(%Blueprint.Document.Fragment.Named{} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(%Blueprint.Document.VariableDefinition{type: type_reference} = node, schema, _) do
    type = type_reference_to_type(type_reference, schema)
    if Type.unwrap(type) do
      %{node | schema_node: type}
    else
      node
    end
  end
  defp handle_node(%Blueprint.Document.Fragment.Inline{type_condition: nil} = node, _, _) do
    node
  end

  defp handle_node(%Blueprint.Document.Fragment.Inline{type_condition: %{name: _}} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(node.type_condition.name)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(%Blueprint.Directive{name: name} = node, schema, adapter) do
    internal_name = adapter.to_internal_name(name, :directive)
    schema_node = schema.__absinthe_directive__(internal_name)
    arguments = Enum.map(node.arguments, &argument_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, arguments: arguments}
  end
  defp handle_node(%Blueprint.Document.Operation{type: op_type} = node, schema, adapter) do
    schema_node = schema.__absinthe_type__(op_type)
    selections_with_schema = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, selections: selections_with_schema}
  end
  defp handle_node(node, _, _) do
    node
  end

  @type_mapping %{
    Blueprint.TypeReference.List => Type.List,
    Blueprint.TypeReference.NonNull => Type.NonNull
  }
  defp type_reference_to_type(%Blueprint.TypeReference.Name{} = node, schema) do
    Schema.lookup_type(schema, node.name)
  end
  for {blueprint_type, core_type} <- @type_mapping do
    defp type_reference_to_type(%unquote(blueprint_type){} = node, schema) do
      inner = type_reference_to_type(node.of_type, schema)
      %unquote(core_type){of_type: inner}
    end
  end

  # Given a blueprint field node, fill in its schema node
  #
  # (If it's a fragment spread or inline fragment, we skip it, as the
  # appropriate `handle_node` for the fragment type will call this itself.)
  @spec selection_with_schema_node(Blueprint.Document.selection_t, Type.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Type.t
  defp selection_with_schema_node(%Blueprint.Document.Field{} = node, parent_schema_node, schema, adapter) do
    schema_node = find_schema_field(parent_schema_node, node.name, schema, adapter)
    if schema_node do
      selections = Enum.map(node.selections, &selection_with_schema_node(&1, schema_node, schema, adapter))
      arguments = Enum.map(node.arguments, &argument_with_schema_node(&1, schema_node, schema, adapter))
      %{node | schema_node: schema_node, selections: selections, arguments: arguments}
    else
      node
    end
  end
  # Inline fragments use their type condition to determine child field schema
  # nodes. For inline fragments without type conditions, we set it to that of
  # its parent here so the `handle_node` that takes care of the inline fragment
  #
  defp selection_with_schema_node(%Blueprint.Document.Fragment.Inline{type_condition: nil} = node, parent_schema_node, schema, _) do
    base_type = case parent_schema_node do
      %{type: type} ->
        type
      other ->
        other
    end
    type = Type.unwrap(Type.expand(base_type, schema))
    %{node | type_condition: %Blueprint.TypeReference.Name{name: type.name}}
  end
  defp selection_with_schema_node(node, _, _, _) do
    node
  end

  # Given a schema type, lookup a child field definition
  @spec find_schema_field(nil | Type.t, String.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: nil | Type.Field.t
  defp find_schema_field(_, "__" <> introspection_field, _, _) do
    Absinthe.Introspection.Field.meta(introspection_field)
  end
  defp find_schema_field(%{of_type: type}, name, schema, adapter) do
    find_schema_field(type, name, schema, adapter)
  end
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
  @spec argument_with_schema_node(Blueprint.Input.Argument.t, Type.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Type.t
  defp argument_with_schema_node(node, nil, _, _) do
    node
  end
  defp argument_with_schema_node(%{name: name} = node, parent_schema_node, schema, adapter) do
    schema_node = find_schema_argument(parent_schema_node, name, adapter)
    input_value = value_with_schema_node(node.input_value, schema_node, schema, adapter)
    %{node | schema_node: schema_node, input_value: input_value}
  end

  # Given a blueprint provided value node, fill in its schema node
  @spec value_with_schema_node(Blueprint.Input.Value.t, Type.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Type.Input.t
  defp value_with_schema_node(node, nil, _, _) do
    node
  end
  defp value_with_schema_node(nil, _, _, _) do
    nil
  end
  defp value_with_schema_node(node, %Type.NonNull{of_type: type}, schema, adapter) do
    value_with_schema_node(node, type, schema, adapter)
  end
  defp value_with_schema_node(node, %Type.List{of_type: type}, schema, adapter) do
    value_with_schema_node(node, type, schema, adapter)
  end
  defp value_with_schema_node(node, %Type.Scalar{} = parent_schema_node, _, _) do
    %{node | schema_node: parent_schema_node}
  end
  defp value_with_schema_node(node, %Type.Enum{} = parent_schema_node, _, _) do
    %{node | schema_node: parent_schema_node}
  end
  defp value_with_schema_node(%Blueprint.Input.Object{} = node, parent_schema_node, schema, adapter) do
    schema_node = expand_type(parent_schema_node, schema)
    fields = Enum.map(node.fields, &input_field_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, fields: fields}
  end
  defp value_with_schema_node(%Blueprint.Input.List{} = node, parent_schema_node, schema, adapter) do
    schema_node = expand_type(parent_schema_node.type, schema)
    values = Enum.map(node.values, &value_with_schema_node(&1, schema_node, schema, adapter))
    %{node | schema_node: schema_node, values: values}
  end
  # Coerce argument-level lists
  defp value_with_schema_node(%node_type{} = node, %Type.Argument{type: %Type.List{}} = type, schema, adapter) when node_type != Blueprint.Input.List do
    Blueprint.Input.List.wrap(node)
    |> value_with_schema_node(type, schema, adapter)
  end
  defp value_with_schema_node(node, parent_schema_node, schema, _) do
    schema_node = expand_type(parent_schema_node.type, schema)
    %{node | schema_node: schema_node}
  end

  # Expand type, but strip wrapping argument node
  @spec expand_type(Type.t, Schema.t) :: Type.t
  defp expand_type(%{type: type}, schema) do
    Type.expand(type, schema)
  end
  defp expand_type(type, schema) do
    Type.expand(type, schema)
  end

  @spec input_field_with_schema_node(Blueprint.Input.Field.t, Type.t, Absinthe.Schema.t, Absinthe.Adapter.t) :: Type.t
  defp input_field_with_schema_node(%Blueprint.Input.Field{} = node, parent_schema_node, schema, adapter) do
    schema_node = find_schema_field(parent_schema_node, node.name, schema, adapter)
    value = value_with_schema_node(node.value, schema_node, schema, adapter)
    %{node | schema_node: schema_node, value: value}
  end
  defp input_field_with_schema_node(node, _, _, _) do
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
