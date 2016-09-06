defmodule Absinthe.Phase.Document.Arguments.Coercion do
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
