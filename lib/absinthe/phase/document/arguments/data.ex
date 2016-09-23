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
  - If non-null arguments are not provided (eg, a `Argument.t` is missing
    from `normalized_value`), add a stub `Argument.t` and flag it as
    `:invalid` and `:missing`.
  - If non-null input fields are not provided (eg, an `Input.Field.t` is
    missing from `normalized_value`), add a stub `Input.Field.t` and flag it as
    `:invalid` and `:missing`.

  Note that the limited validation that occurs in this phase is limited to
  setting the `data_value` to `nil`, adding flags to the `normalized_value`,
  and building stub fields/arguments when missing values are required. Actual
  addition of errors is handled by validation phases.
  """

  alias Absinthe.{Blueprint, Type}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &(handle_node(&1, input.adapter)))
    {:ok, result}
  end

  @argument_hosts [
    Blueprint.Document.Field,
    Blueprint.Directive,
  ]

  defp handle_node(%{normalized_value: %{schema_node: nil}} = node, _) do
    node
  end
  defp handle_node(%argument_host{schema_node: schema_node} = node, adapter) when not is_nil(schema_node) and argument_host in @argument_hosts do
    missing = generate_missing_arguments(node, adapter)
    %{node | arguments: missing ++ node.arguments}
  end
  # defp handle_node(%Blueprint.Input.Argument{normalized_value: nil, schema_node: %{type: %Type.NonNull{}}} = node, _adapter) do
  #   flag_invalid(node, :missing)
  # end

  defp handle_node(%{input_value: %Blueprint.Input.Value{} = input} = node, adapter) do
    case build_value(input.normalized, adapter) do
      {:ok, value} ->
        %{node | data_value: value}
      {:error, normalized_value} ->
        %{node | input_value: %{ input | normalized: normalized_value}}
    end
  end
  defp handle_node(node, _adapter) do
    node
  end

  defp build_value(%{schema_node: nil} = node, _adapter) do
    {:error, flag_invalid(node, :no_schema_node)}
  end
  defp build_value(%{schema_node: %Type.NonNull{of_type: type}} = node, adapter) do
    case build_value(%{node | schema_node: type}, adapter) do
      {:error, node} ->
        # Rewrap
        node = %{node | schema_node: %Type.NonNull{of_type: node.schema_node}}
        {:error, node}
      other ->
        other
    end
  end
  defp build_value(%Blueprint.Input.Object{schema_node: %{fields: _}} = node, adapter) do
    {result, fields} = node.fields
    |> Enum.reduce({%{}, []}, fn
      field, {data, fields} ->
        case build_value(field, adapter) do
          {:ok, identifier, value} ->
            {Map.put(data, identifier, value), [field | fields]}
          {:error, field} ->
            {data, [field | fields]}
        end
    end)
    missing_fields = Enum.flat_map(node.schema_node.fields, fn
      {_, %Type.Field{type: %Type.NonNull{}, deprecation: nil} = schema_field} ->
        if Enum.any?(fields, &(match?(%Blueprint.Input.Field{schema_node: ^schema_field}, &1))) do
          []
        else
          # Generate a stub field
          [
            %Blueprint.Input.Field{
              name: schema_field.name |> adapter.to_external_name(:field),
              value: nil,
              input_value: %Blueprint.Input.Value{literal: nil},
              schema_node: schema_field,
              source_location: node.source_location
            }
            |> flag_invalid(:missing)
          ]
        end
      _ ->
        []
    end)
    fields = fields ++ missing_fields
    if any_invalid?(fields) do
      node = %{node | fields: fields}
      {:error, flag_invalid(node, :bad_fields)}
    else
      {:ok, result}
    end
  end
  defp build_value(%Blueprint.Input.Field{} = node, adapter) do
    case build_value(node.value, adapter) do
      {:ok, value} ->
        {:ok, node.schema_node.__reference__.identifier, value}
      {:error, node_value} ->
        node = %{node | value: node_value}
        {:error, flag_invalid(node, :bad_value)}
    end
  end
  defp build_value(%{schema_node: %Type.Scalar{} = schema_node} = node, _adapter) do
    schema_node = schema_node |> unwrap_non_null
    case Type.Scalar.parse(schema_node, node) do
      :error ->
        {:error, flag_invalid(node, :bad_parse)}
      other ->
        other
    end
  end
  defp build_value(%{schema_node: %Type.Enum{} = schema_node} = node, _adapter) do
    case Type.Enum.parse(schema_node, node) do
      {:ok, %{value: value}} ->
        {:ok, value}
      :error ->
        {:error, flag_invalid(node, :bad_parse)}
    end
  end
  defp build_value(%Blueprint.Input.List{} = node, adapter) do
    {result, list_values} = Enum.reduce(node.values, {[], []}, fn
      list_value, {data, list_values} ->
        case build_value(list_value, adapter) do
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
      {:ok, Enum.reverse(result)}
    end
  end
  defp build_value(%{flags: _} = node, _adapter) do
    {:error, flag_invalid(node, :unknown_data_value)}
  end
  defp build_value(node, _adapter) do
    {:error, node}
  end

  @spec unwrap_non_null(Type.NonNull.t | Type.t) :: Type.t
  defp unwrap_non_null(%Type.NonNull{of_type: type}) do
    type
  end
  defp unwrap_non_null(other) do
    other
  end

  defp generate_missing_arguments(node, adapter) do
    Enum.flat_map(node.schema_node.args, fn
      {_, %Type.Argument{type: %Type.NonNull{}, deprecation: nil} = schema_argument} ->
        if Enum.any?(node.arguments, &(match?(%Blueprint.Input.Argument{schema_node: ^schema_argument}, &1))) do
          []
        else
          # Generate a stub argument
          [
            %Blueprint.Input.Argument{
              name: schema_argument.name |> adapter.to_external_name(:argument),
              input_value: %Blueprint.Input.Value{literal: nil},
              value: nil,
              schema_node: schema_argument,
              source_location: node.source_location
            }
            |> flag_invalid(:missing)
          ]
        end
      _ ->
        []
    end)
  end

end
