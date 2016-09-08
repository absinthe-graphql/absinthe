defmodule Absinthe.Phase.Document.Arguments.Coercion do
  @moduledoc """
  Coerce variable string inputs to enums when appropriate.

  A literal enum like `foo(arg: ENUM)` is parsed as an `Input.Enum` struct.

  However when a variable is used `foo(arg: $enumVar)` the variable input ends up
  being an `Input.String` because the variable handler does not yet know the
  schema type. This phase coerces string to enum inputs when the schema type
  is an Enum.

  This may be merged into another phase in the future.
  """

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}

  @spec run(Blueprint.t) :: {:ok, Blueprint.t}
  def run(input) do
    node = Blueprint.prewalk(input, &coerce_node/1)
    {:ok, node}
  end

  defp coerce_node(%Blueprint.Input.String{schema_node: %Type.Enum{}} = node) do
    Map.put(node, :__struct__, Blueprint.Input.Enum)
  end
  defp coerce_node(node), do: node

end
