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

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, options \\ []) do
    variables = options[:variables] || %{}
    {:ok, update_operations(input, variables)}
  end

  def update_operations(input, variables) do
    operations =
      for op <- input.operations do
        update_operation(op, variables)
      end

    %{input | operations: operations}
  end

  def update_operation(%{variable_definitions: variable_definitions} = operation, variables) do
    {variable_definitions, provided_values} =
      Enum.map_reduce(variable_definitions, %{}, fn node, acc ->
        provided_value = calculate_value(node, variables)

        {
          %{node | provided_value: provided_value},
          Map.put(acc, node.name, provided_value)
        }
      end)

    %{operation | variable_definitions: variable_definitions, provided_values: provided_values}
  end

  defp calculate_value(node, variables) do
    case Map.fetch(variables, node.name) do
      :error ->
        node.default_value

      {:ok, value} ->
        value
        |> preparse_nil
        |> Blueprint.Input.parse()
    end
  end

  defp preparse_nil(nil), do: %Blueprint.Input.Null{}
  defp preparse_nil(other), do: other
end
