defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType do

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    {result, _} = Blueprint.prewalk(input, input.schema, &handle_node/2)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{schema_node: %{type: type_identifier}, literal_value: literal, normalized_value: norm, data_value: nil} = node, schema) when not is_nil(norm) do
    expected_type = schema.__absinthe_type__(type_identifier)
    flags = [:invalid | node.flags]
    errors = [error(expected_type, literal, node) | node.errors]
    {%{node | flags: flags, errors: errors}, schema}
  end
  defp handle_node(node, schema) do
    {node, schema}
  end

  defp error(expected_type, literal, node) do
    Phase.Error.new(
      __MODULE__,
      ~s(Expected type "#{expected_type.name}", found #{literal.value}),
      node.source_location
    )
  end

end
