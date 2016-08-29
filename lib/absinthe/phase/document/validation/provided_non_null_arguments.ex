defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments do
  @moduledoc """
  Validates document to ensure that all non-null arguments are provided.
  """

  alias Absinthe.{Blueprint, Phase, Type}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    {result, _} = Blueprint.prewalk(input, input.schema, &handle_node/2)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{data_value: nil} = node, schema) do
    if Enum.member?(node.flags, :missing) do
      node = %{node | errors: [error(node, node.schema_node.type, schema) | node.errors]}
      {node, schema}
    else
      {node, schema}
    end
  end
  defp handle_node(node, schema) do
    {node, schema}
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
