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
    errors = [error(node, argument_error_message(node, schema)) | node.errors]
    {%{node | flags: flags, errors: errors}, schema}
  end
  defp handle_node(%Blueprint.Input.Object{} = node, schema) do
    if Enum.member?(node.flags, :invalid) do
      add_errors = node.fields
      |> Enum.reduce([], fn
        field, acc ->
          if Enum.member?(field.flags, :invalid) do
            [error(field, argument_field_error_message(field, schema)) | acc]
          else
            acc
          end
      end)
      node = %{node | errors: add_errors ++ node.errors}
      {node, schema}
    else
      {node, schema}
    end
  end
  defp handle_node(%Blueprint.Input.List{} = node, schema) do
    if Enum.member?(node.flags, :invalid) do
      add_errors = node.values
      |> Enum.with_index
      |> Enum.reduce([], fn
        {value_node, index}, acc ->
          if Enum.member?(value_node.flags, :invalid) do
            [error(value_node, argument_list_item_error_message(index, value_node, schema)) | acc]
          else
            acc
          end
      end)
      node = %{node | errors: add_errors ++ node.errors}
      {node, schema}
    else
      {node, schema}
    end
  end
  defp handle_node(node, schema) do
    {node, schema}
  end

  defp error(node, message) do
    Phase.Error.new(
      __MODULE__,
      message,
      node.source_location
    )
  end

  defp argument_field_error_message(node, schema) do
    ~s(In field "#{node.name}": Unknown field.)
  end
  defp argument_error_message(node, schema) do
    type_name = Type.name(node.schema_node.type, schema)
    ~s(Expected type "#{type_name}", found #{Blueprint.Input.inspect node.literal_value})
  end
  defp argument_list_item_error_message(index, node, schema) do
    type_name = Type.name(node.schema_node, schema)
    ~s(In element ##{index + 1}: Expected type "#{type_name}", found #{Blueprint.Input.inspect node})
  end

end
