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
  alias Absinthe.{Blueprint, Pipeline}

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, options \\ []) do
    variables = options[:variables] || %{}

    result = Blueprint.update_current(blueprint, fn operation ->
      operation
      |> update_operation(variables, blueprint, options)
    end)

    {:ok, result}
  end

  def update_operation(%{variable_definitions: variable_definitions} = operation, variables, root, options) do
    variable_definitions = Enum.map(variable_definitions, fn node ->
      input =
        variables
        |> Map.get(node.name, node.default_value)
        |> Blueprint.Input.parse

      %{node | input: %Blueprint.Input.Value{literal: input, normalized: input}}
      |> validate_variable(root, options)
    end)

    %{operation | variable_definitions: variable_definitions}
  end

  def validate_variable(variable_def, root, options) do
    pipeline = Pipeline.for_variables(root.schema, options)

    {:ok, variable_def, _} = Pipeline.run(variable_def, pipeline)
    variable_def
  end

end
