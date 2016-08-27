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
    errors = [error(type_reference, schema, literal, node) | node.errors]
    {%{node | flags: flags, errors: errors}, schema}
  end
  defp handle_node(node, schema) do
    {node, schema}
  end

  defp error(type_reference, schema, literal, node) do
    type_name = Type.name(type_reference, schema)
    Phase.Error.new(
      __MODULE__,
      ~s(Expected type "#{type_name}", found #{Blueprint.Input.inspect literal}),
      node.source_location
    )
  end

end
