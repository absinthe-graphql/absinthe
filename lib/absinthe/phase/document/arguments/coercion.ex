defmodule Absinthe.Phase.Document.Arguments.Coercion do
  @moduledoc """
  Coerce variable string inputs to enums when appropriate.

  A literal enum like `foo(arg: ENUM)` is parsed as an `Input.Enum` struct.

  However when a variable is used `foo(arg: $enumVar)` the variable input ends up
  being an `Input.String` because the variable handler does not yet know the
  schema type. This phase coerces string to enum inputs when the schema type
  is an Enum.

  This will also coerce non list inputs into list inputs IE
  ```
  foo(ids: 1)
  ```
  becomes
  ```
  foo(ids: [1])
  ```

  if `ids` is a list type.
  """

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}
  alias Absinthe.Blueprint.Input

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &coerce_node/1)
    {:ok, node}
  end

  defp coerce_node(%{literal: %Input.Variable{}} = node) do
    node = Blueprint.prewalk(node, fn
      %Input.String{schema_node: %Type.Enum{}} = input ->
        Map.put(input, :__struct__, Input.Enum)

      node ->
        node
    end)
    {:halt, node}
  end
  # Coerce non lists to lists in inputs.
  defp coerce_node(%Input.Value{schema_node: %Type.List{} = list_schema_node} = node) do
    %{node | normalized: Input.List.wrap(node.normalized, list_schema_node)}
  end
  defp coerce_node(node), do: node

end
