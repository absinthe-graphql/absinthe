defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments do
  @moduledoc """
  Validates document to ensure that all non-null arguments are provided.
  """

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &(handle_node(&1, input.schema)))
    {:ok, result}
  end

  # Find the missing arguments
  @spec handle_node(Blueprint.node_t, Schema.t) :: Blueprint.node_t
  defp handle_node(%Blueprint.Input.Argument{data_value: nil} = node, schema) do
    if Enum.member?(node.flags, :missing) do
      %{node | errors: [error(node, node.schema_node.type, schema) | node.errors]}
    else
      node
    end
  end
  # Skip
  defp handle_node(node, _) do
    node
  end

  # Generate the error for this validation
  @spec error(Blueprint.node_t, Type.t, Schema.t) :: Phase.Error.t
  defp error(node, type, schema) do
    type_name = Type.name(type, schema)
    Phase.Error.new(
      __MODULE__,
      ~s(Expected type "#{type_name}", found null.),
      node.source_location
    )
  end

end
