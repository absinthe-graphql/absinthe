defmodule Absinthe.Phase.Operation.Variables do
  @moduledoc """
  For a given operation name, provided a mapping of variable names to literal
  values:

  - Add errors to any variable definition that is non-null but is not given a
    value
  - Set the `provided_value` field of all `Blueprint.Input.Argument.t` structs
    that are using variables to the values provided for those variables (or
    their defined defaults)

  ## Examples

  Given a GraphQL document that looks like:

  ```
  query Item($id: ID!) {
  item(id: $id) {
  name
  }
  }
  ```

  And this phase configuration:

  ```
  run(blueprint, %{operation_name: "Item", variables: %{"id" => "1234"}})
  ``

  The `item` field's `id` argument struct would be modified to have a
  `provided_value` of `"1234"`.

  If, the following was used (note no `"id"` variable value is given):

  ```
  run(blueprint, %{operation_name: "Item", variables: %{}})
  ``

  The variable definition for `id` would have an error record in its `errors`
  field.
  """

  alias Absinthe.{Blueprint, Phase}

  @error_not_provided "value not provided"

  @spec run(Blueprint.t, %{operation_name: nil | String.t, variables: %{String.t => any}}) :: {:ok, Blueprint.t}
  def run(input, options) do
    acc = Map.put(options, :active_operation, false)
    {node, _} = Blueprint.Mapper.prewalk(input, acc, &handle_node/2)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t, map) :: {Blueprint.node_t, map}
  # Matching operation: Mark active, process variable definitions
  defp handle_node(%Blueprint.Operation{name: name} = node, %{operation_name: name} = acc) do
    # Let children know they're in the right operation
    acc = %{acc | active_operation: true}
    # We need to traverse the variable definitions first, so that we can harvest
    # any default values and put them in the `variables` field of our accumulator
    {variable_definitions, acc} = Enum.map_reduce(node.variable_definitions, acc, &process_variable_definition/2)
    {
      struct(node, variable_definitions: variable_definitions),
      acc
    }
  end
  # Non-matching operation: Mark inactive
  defp handle_node(%Blueprint.Operation{} = node, acc) do
    {node, %{acc | active_operation: false}}
  end
  # Argument using a variable: Set provided value
  defp handle_node(%Blueprint.Input.Argument{value: %Blueprint.Input.Variable{name: variable_name}} = node, %{active_operation: true} = acc) do
    {
      struct(node, provided_value: Map.get(acc.variables, variable_name)),
      acc
    }
  end
  # All other nodes: return unchanged
  defp handle_node(node, acc) do
    {node, acc}
  end

  defp process_variable_definition(node, acc) do
    case {node.type, Map.get(acc.variables, node.name)} do
      # If it's non-null and there's no value, add an error
      {%Blueprint.NonNullType{}, nil} ->
        {
          update_in(node.errors, &[error(@error_not_provided) | &1]),
          acc
        }
      # If it's optional, assign its (bare, unwrapped) default value to the
      # variables map
      {_, nil} ->
        {
          node,
          %{acc | variables: Map.put(acc.variables, node.name, Blueprint.Input.unwrap(node.default_value))}
        }
      # All else, no-op
      {_, _} ->
        {
          node,
          acc
        }
    end
  end

  @spec error(String.t) :: Phase.Error.t
  # Build an error
  defp error(message) do
    %Phase.Error{
      message: message,
      phase: __MODULE__,
    }
  end

end
