defmodule Absinthe.Phase.Document.Arguments.Data do

  alias Absinthe.{Blueprint, Type}

  def run(input) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%{normalized_value: %{schema_node: nil}} = node) do
    node
  end
  defp handle_node(%Blueprint.Input.Argument{} = node) do
    case build_value(node.normalized_value) do
      {:ok, value} ->
        %{node | data_value: value}
      _ ->
        node
    end
  end
  defp handle_node(node) do
    node
  end

  defp build_value(%{schema_node: nil}) do
    :error
  end
  defp build_value(%Blueprint.Input.Object{} = node) do
    result = node.fields
    |> Enum.reduce(%{}, fn
      field, acc ->
        case build_value(field) do
          {:ok, identifier, value} ->
            Map.put(acc, identifier, value)
          _ ->
            acc
        end
    end)
    {:ok, result}
  end
  defp build_value(%Blueprint.Input.Field{} = node) do
    case build_value(node.value) do
      {:ok, value} ->
        {:ok, node.schema_node.__reference__.identifier, value}
      _ ->
        :error
    end
  end
  defp build_value(%{value: value, schema_node: %Type.Scalar{} = schema_node}) do
    Type.Scalar.parse(schema_node, value)
  end
  defp build_value(_) do
    :error
  end

end
