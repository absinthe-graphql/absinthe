defmodule Absinthe.Phase.Document.Validation.ArgumentListItemsOfCorrectType do

  alias Absinthe.{Blueprint, Phase, Type}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    # TODO: It would be nice to only walk down `normalized_value` fields
    # of `Blueprint.Input.Argument.t`; we don't need to traverse
    # `literal_value`.
    {result, _} = Blueprint.prewalk(input, input.schema, &handle_node/2)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.List{} = node, schema) do
    if Enum.member?(node.flags, :invalid) do
      add_errors = node.values
      |> Enum.with_index
      |> Enum.reduce([], fn
        {value_node, index}, acc ->
          if Enum.member?(value_node.flags, :invalid) do
            [error(index, value_node, schema) | acc]
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

  defp error(index, node, schema) do
    Phase.Error.new(
      __MODULE__,
      error_message(index, node, schema),
      node.source_location
    )
  end

  defp error_message(index, node, schema) do
    type_name = Type.name(node.schema_node, schema)
    ~s(In element ##{index + 1}: Expected type "#{type_name}", found #{Blueprint.Input.inspect node})
  end

end
