defmodule Absinthe.Phase.Document.Variables do
  @moduledoc false

  # Provided a set of variable values:
  #
  # - Set the `variables` field on the `Blueprint.Document.Operation.t` to the reconciled
  #   mapping of variable values, supporting defined default values.
  #
  # ## Examples
  #
  # Given a GraphQL document that looks like:
  #
  # ```
  # query Item($id: ID!, $text = String = "Another") {
  #   item(id: $id, category: "Things") {
  #     name
  #   }
  # }
  # ```
  #
  # And this phase configuration:
  #
  # ```
  # run(blueprint, %{"id" => "1234"})
  # ``
  #
  # - The operation's `variables` field would have an `"id"` value set to
  #   `%Blueprint.Input.StringValue{value: "1234"}`
  # - The operation's `variables` field would have an `"text"` value set to
  #   `%Blueprint.Input.StringValue{value: "Another"}`
  #
  # ```
  # run(blueprint, %{})
  # ```
  #
  # - The operation's `variables` field would have an `"id"` value set to
  #   `nil`
  # - The operation's `variables` field would have an `"text"` value set to
  #   `%Blueprint.Input.StringValue{value: "Another"}`
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, options \\ []) do
    do_run(input, Map.new(options))
  end

  def do_run(input, %{variables: values}) do
    acc = %{raw: values, processed: %{}}
    {node, _} = Blueprint.postwalk(input, acc, &handle_node/2)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, map) :: {Blueprint.node_t, map}
  defp handle_node(%Blueprint.Document.VariableDefinition{} = node, acc) do
    provided_value =
      acc.raw
      |> Map.get(node.name, node.default_value)
      |> Blueprint.Input.parse

    {
      %{node | provided_value: provided_value},
      update_in(acc.processed, &Map.put(&1, node.name, provided_value))
    }
  end
  defp handle_node(%Blueprint.Document.Operation{} = node, acc) do
    {
      %{node | provided_values: acc.processed},
      acc
    }
  end
  defp handle_node(node, acc) do
    {node, acc}
  end

end
