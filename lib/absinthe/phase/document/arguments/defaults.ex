defmodule Absinthe.Phase.Document.Arguments.Defaults do
  @moduledoc """
  Populate all arguments in the document with their provided values:

  - If a literal value is provided for an argument, set the `Argument.t`'s
    `normalized_value` field to that value.
  - If a variable is provided for an argument, set the `Argument.t`'s
    `normalized_value` to the reconciled value for the variable
    (Note: this requires the `Phase.Document.Variables` phase as a
    prerequisite).

  Note that no validation occurs in this phase.
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &populate_node/1)
    {:ok, node}
  end

  defp populate_node(%{schema_node: nil} = node), do: node
  defp populate_node(%{arguments: arguments, schema_node: schema_node} = node) do
    %{node | arguments: fill_defaults(arguments, schema_node.args, node.source_location)}
  end
  defp populate_node(node), do: node

  defp fill_defaults(arguments, schema_args, source_location) do
    arguments
    |> Enum.filter(&(&1.schema_node))
    |> Enum.reduce(schema_args, fn
      %{schema_node: %{__reference__: %{identifier: id}}}, acc ->
        Map.delete(acc, id)
      _, acc ->
        acc
    end)
    |> Enum.reduce(arguments, fn
      {_, %{default_value: nil}}, arguments ->
        arguments
      {_, missing_optional_arg_schema_node}, arguments ->
        [build_optional_argument(missing_optional_arg_schema_node, source_location) | arguments]
    end)
  end

  defp build_optional_argument(schema_node_arg, source_location) do
    default = schema_node_arg.default_value
    %Blueprint.Input.Argument{
      name: schema_node_arg.name,
      input_value: %Blueprint.Input.Value{literal: nil},
      value: default,
      schema_node: schema_node_arg,
      source_location: source_location
    }
  end

end
