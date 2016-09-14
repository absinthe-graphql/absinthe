defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType do
  @moduledoc """
  Validates document to ensure that all arguments are of the correct type.
  """

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run this validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &(handle_node(&1, input.schema)))
    {:ok, result}
  end

  # Check arguments, objects, fields, and lists
  @spec handle_node(Blueprint.node_t, Schema.t) :: Blueprint.node_t
  defp handle_node(%Blueprint.Input.Argument{schema_node: %{type: _}, normalized_value: norm, data_value: nil} = node, schema) when not is_nil(norm) do
    node
    |> flag_invalid(:bad_argument)
    |> put_error(error(node, error_message(node, schema)))
  end
  defp handle_node(%Blueprint.Input.Object{flags: %{invalid: _}} = node, schema) do
    fields = Enum.map(node.fields, &handle_value(&1, schema))
    %{node | fields: Enum.reverse(fields)}
  end
  defp handle_node(%Blueprint.Input.List{flags: %{invalid: _}} = node, schema) do
    values = Enum.map(node.values, &handle_value(&1, schema))
    %{node | values: Enum.reverse(values)}
  end
  defp handle_node(node, _) do
    node
  end

  defp handle_value(%{flags: %{invalid: _}} = node, schema) do
    node
    |> put_error(error(node, error_message(node, schema)))
  end
  defp handle_value(node, _) do
    node
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t, String.t) :: Phase.Error.t
  defp error(node, message) do
    Phase.Error.new(
      __MODULE__,
      message,
      node.source_location
    )
  end

  # Generate the error message
  @spec error_message(Blueprint.Input.t, Schema.t) :: String.t
  defp error_message(%Blueprint.Input.Argument{} = node, schema) do
    error_message(node.schema_node.type, node.literal_value, schema)
  end
  defp error_message(%Blueprint.Input.Field{schema_node: nil}, _) do
    "Unknown field."
  end
  defp error_message(%Blueprint.Input.Field{} = node, schema) do
    error_message(node.schema_node.type, node.value, schema)
  end
  defp error_message(node, schema) do
    error_message(node.schema_node, node, schema)
  end

  # Generate an error message detailing the expected type and given value
  @spec error_message(Type.t, any, Schema.t) :: String.t
  defp error_message(type, value, schema) do
    type_name = Type.name(type, schema)
    ~s(Expected type "#{type_name}", found #{Blueprint.Input.inspect value})
  end

end
