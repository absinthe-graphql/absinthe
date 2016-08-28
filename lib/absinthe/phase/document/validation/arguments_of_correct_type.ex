defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType do

  alias Absinthe.{Blueprint, Phase, Type}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    {result, _} = Blueprint.prewalk(input, input.schema, &handle_node/2)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{schema_node: %{type: type_reference}, literal_value: literal, normalized_value: norm, data_value: nil} = node, schema) when not is_nil(norm) do
    type_identifier = Type.unwrap(type_reference)
    flags = [:invalid | node.flags]
    errors = [error(node, schema) | node.errors]
    {%{node | flags: flags, errors: errors}, schema}
  end
  defp handle_node(%Blueprint.Input.Argument{schema_node: %{type: type_reference}, literal_value: literal, normalized_value: norm, data_value: _} = node, schema) when not is_nil(norm) do
    {node, schema}
  end
  defp handle_node(node, schema) do
    {node, schema}
  end

  defp error(node, schema) do
    Phase.Error.new(
      __MODULE__,
      error_message(node, schema),
      node.source_location
    )
  end

  defp error_message(node, schema) do
    type_name = Type.name(node.schema_node.type, schema)
    ~s(Expected type "#{type_name}", found #{Blueprint.Input.inspect node.literal_value})
  end

end
