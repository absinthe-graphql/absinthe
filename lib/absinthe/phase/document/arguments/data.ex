defmodule Absinthe.Phase.Document.Arguments.Data do
  @moduledoc """
  Populate all arguments in the document with their provided data values:

  - If valid data is available for an argument, set the `Argument.t`'s
    `data_value` field to that value.
  - If no valid data is available for an argument, set the `Argument.t`'s
    `data_value` to `nil`.
  - When determining the value of the argument, mark any invalid nodes
    in the `Argument.t`'s `normalized_value` tree with `:invalid` and a
    reason.

  Note that the limited validation that occurs in this phase is limited to
  setting the `data_value` to `nil` and adding flags to the `normalized_value`.
  """

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
      {:error, normalized_value} ->
        %{node | normalized_value: normalized_value}
    end
  end
  defp handle_node(node) do
    node
  end

  defp build_value(%{schema_node: nil} = node) do
    {:error, flag_invalid(node, :no_schema_node)}
  end
  defp build_value(%{schema_node: %Type.NonNull{of_type: type}} = node) do
    case build_value(%{node | schema_node: type}) do
      {:error, node} ->
        # Rewrap
        node = %{node | schema_node: %Type.NonNull{of_type: node.schema_node}}
        {:error, node}
      other ->
        other
    end
  end
  defp build_value(%Blueprint.Input.Object{} = node) do
    {result, fields} = node.fields
    |> Enum.reduce({%{}, []}, fn
      field, {data, fields} ->
        case build_value(field) do
          {:ok, identifier, value} ->
            {Map.put(data, identifier, value), [field | fields]}
          {:error, field} ->
            {data, [field | fields]}
        end
    end)
    if any_invalid?(fields) do
      node = %{node | fields: fields}
      {:error, flag_invalid(node, :bad_fields)}
    else
      {:ok, result}
    end
  end
  defp build_value(%Blueprint.Input.Field{} = node) do
    case build_value(node.value) do
      {:ok, value} ->
        {:ok, node.schema_node.__reference__.identifier, value}
      {:error, node_value} ->
        node = %{node | value: node_value}
        {:error, flag_invalid(node, :bad_value)}
    end
  end
  defp build_value(%{schema_node: %Type.Scalar{} = schema_node} = node) do
    schema_node = schema_node |> unwrap_non_null
    case Type.Scalar.parse(schema_node, node) do
      :error ->
        {:error, flag_invalid(node, :bad_parse)}
      other ->
        other
    end
  end
  defp build_value(%{value: value, schema_node: %Type.Enum{} = schema_node} = node) do
    case Type.Enum.parse(schema_node, node) do
      :error ->
        {:error, flag_invalid(node, :bad_parse)}
      other ->
        other
    end
  end
  defp build_value(%Blueprint.Input.List{} = node) do
    {result, list_values} = Enum.reduce(node.values, {[], []}, fn
      list_value, {data, list_values} ->
        case build_value(list_value) do
          {:ok, value} ->
            {[value | data], [list_value | list_values]}
          {:error, list_value} ->
            {data, [list_value | list_values]}
        end
    end)
    if any_invalid?(list_values) do
      node = %{node | values: list_values |> Enum.reverse}
      {:error, flag_invalid(node, :bad_values)}
    else
      {:ok, result}
    end
  end
  defp build_value(node) do
    {:error, flag_invalid(node, :unknown_data_value)}
  end

  @spec any_invalid?([Blueprint.Input.t]) :: boolean
  defp any_invalid?(inputs) do
    Enum.any?(inputs, &(Enum.member?(&1.flags, :invalid)))
  end

  defp flag_invalid(node, flag) do
    %{node | flags: [flag | with_invalid(node.flags)]}
  end
  defp with_invalid(flags) do
    if Enum.member?(flags, :invalid) do
      flags
    else
      [:invalid | flags]
    end
  end

  @spec unwrap_non_null(Type.NonNull.t | Type.t) :: Type.t
  defp unwrap_non_null(%Type.NonNull{of_type: type}) do
    type
  end
  defp unwrap_non_null(other) do
    other
  end

end
