defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments do
  @moduledoc """
  Validates document to ensure that all non-null arguments are provided.
  """

  alias Absinthe.{Blueprint, Phase, Type}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &(handle_node(&1, input.schema)))
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{data_value: nil} = node, schema) do
    if Enum.member?(node.flags, :missing) do
      %{node | errors: [error(node, node.schema_node.type, schema) | node.errors]}
    else
      node
    end
  end
  defp handle_node(node, _) do
    node
  end

  defp error(node, type, schema) do
    type_name = Type.name(type, schema)
    Phase.Error.new(
      __MODULE__,
      ~s(Expected type "#{type_name}", found null.),
      node.source_location
    )
  end

end
