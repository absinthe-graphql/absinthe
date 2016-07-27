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
  defp build_value(%{schema_node: %Type.NonNull{of_type: type}} = node) do
    %{node | schema_node: type}
    |> build_value
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
    schema_node = schema_node |> unwrap_non_null
    Type.Scalar.parse(schema_node, value)
  end
  defp build_value(%Blueprint.Input.List{values: values}) do
    result = Enum.reduce_while(values, [], fn
      value, list ->
        case build_value(value) do
          {:ok, value} ->
            {:cont, [value | list]}
          :error ->
            {:halt, :error}
        end
    end)
    case result do
      :error ->
        :error
      values ->
        {:ok, Enum.reverse(values)}
    end
  end
  defp build_value(_) do
    :error
  end

  @spec unwrap_non_null(Type.NonNull.t | Type.t) :: Type.t
  defp unwrap_non_null(%Type.NonNull{of_type: type}) do
    type
  end
  defp unwrap_non_null(other) do
    other
  end

end
