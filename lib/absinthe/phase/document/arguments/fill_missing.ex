defmodule Absinthe.Phase.Document.Arguments.FillMissing do
  @moduledoc """
  Fills out missing arguments and input object fields.

  Filling out means inserting a stubbed `Input.Argument` or `Input.Field` struct.

  Only those arguments which are non null and / or have a default value are filled
  out.
  """

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &populate_node(&1, input.adapter))
    {:ok, node}
  end

  defp populate_node(%{schema_node: nil} = node, _adapter), do: node
  defp populate_node(%{arguments: arguments, schema_node: schema_node} = node, adapter) do
    arguments = fill_missing_nodes(Blueprint.Input.Argument, arguments, schema_node.args, node.source_location, adapter)
    %{node | arguments: arguments}
  end
  defp populate_node(%Blueprint.Input.Object{fields: fields, schema_node: schema_node} = node, adapter) do
    fields = fill_missing_nodes(Blueprint.Input.Field, fields, schema_node.args, node.source_location, adapter)
    %{node | fields: fields}
  end
  defp populate_node(node, _adapter), do: node

  defp fill_missing_nodes(type, arguments, schema_args, source_location, adapter) do
    missing_schema_args = find_missing_schema_nodes(arguments, schema_args)

    missing_schema_args
    |> Map.values
    |> Enum.reduce(arguments, fn
      # If the schema node says the argument is non null we want to always add it.
      # Later validations will check if it's both non null and with a nil default value
      %{schema_node: %Type.NonNull{}} = missing_mandatory_arg_schema_node, arguments ->
        arg = build_optional_node(type, missing_mandatory_arg_schema_node, missing_mandatory_arg_schema_node.default_value, source_location, adapter)
        [arg | arguments]

      # If it isn't non null, and there's no default value, there's no point in having it around
      %{default_value: nil}, arguments ->
        arguments

      # Has a default value, we want it.
      missing_optional_arg_schema_node, arguments ->
        arg = build_optional_node(type, missing_optional_arg_schema_node, missing_optional_arg_schema_node.default_value, source_location, adapter)
        [arg | arguments]
    end)
  end

  # Given the set of possible schema args, return only those not supplied in
  # the document argument / fields
  defp find_missing_schema_nodes(nodes, schema_nodes) do
    nodes
    |> Enum.filter(&(&1.schema_node))
    |> Enum.reduce(schema_nodes, fn
      %{schema_node: %{__reference__: %{identifier: id}}}, acc ->
        Map.delete(acc, id)
      _, acc ->
        acc
    end)
  end

  defp build_optional_node(type, schema_node_arg, default, source_location, adapter) do
    struct!(type, %{
      name: schema_node_arg.name |> build_name(adapter, type),
      input_value: %Blueprint.Input.Value{literal: nil},
      value: default,
      schema_node: schema_node_arg,
      source_location: source_location
    })
  end

  defp build_name(name, adapter, Blueprint.Input.Argument) do
    adapter.to_external_name(name, :argument)
  end
  defp build_name(name, adapter, Blueprint.Input.Field) do
    adapter.to_external_name(name, :field)
  end

end
