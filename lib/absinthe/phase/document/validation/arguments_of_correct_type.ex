defmodule Absinthe.Phase.Document.Validation.ArgumentsOfCorrectType do
  @moduledoc false

  # Validates document to ensure that all arguments are of the correct type.

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run this validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  # Check arguments, objects, fields, and lists
  @spec handle_node(Blueprint.node_t(), Schema.t()) :: Blueprint.node_t()
  # handled by Phase.Document.Validation.KnownArgumentNames
  defp handle_node(%Blueprint.Input.Argument{schema_node: nil} = node, _schema) do
    {:halt, node}
  end

  # handled by Phase.Document.Validation.ProvidedNonNullArguments
  defp handle_node(%Blueprint.Input.Argument{input_value: %{normalized: nil}} = node, _schema) do
    {:halt, node}
  end

  defp handle_node(%Blueprint.Input.Argument{flags: %{invalid: _}} = node, schema) do
    descendant_errors = collect_child_errors(node.input_value, schema)

    message =
      error_message(
        node.name,
        Blueprint.Input.inspect(node.input_value),
        descendant_errors
      )

    error = error(node, message)

    node = node |> put_error(error)

    {:halt, node}
  end

  defp handle_node(node, _) do
    node
  end

  defp collect_child_errors(%Blueprint.Input.List{} = node, schema) do
    node.items
    |> Enum.map(& &1.normalized)
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{schema_node: nil} = child, _} ->
        collect_child_errors(child, schema)

      {%{flags: %{invalid: _}} = child, idx} ->
        child_type_name =
          child.schema_node
          |> Type.value_type(schema)
          |> Type.name(schema)

        child_inspected_value = Blueprint.Input.inspect(child)

        [
          value_error_message(idx, child_type_name, child_inspected_value)
          | collect_child_errors(child, schema)
        ]

      {child, _} ->
        collect_child_errors(child, schema)
    end)
  end

  defp collect_child_errors(%Blueprint.Input.Object{} = node, schema) do
    node.fields
    |> Enum.flat_map(fn
      %{flags: %{invalid: _}, schema_node: nil} = child ->
        [unknown_field_error_message(child.name)]

      %{flags: %{invalid: _}} = child ->
        child_type_name =
          Type.value_type(child.schema_node, schema)
          |> Type.name(schema)

        child_errors =
          case child.schema_node do
            %Type.Scalar{} -> []
            %Type.Enum{} -> []
            _ -> collect_child_errors(child.input_value, schema)
          end

        child_inspected_value = Blueprint.Input.inspect(child.input_value)

        [
          value_error_message(child.name, child_type_name, child_inspected_value)
          | child_errors
        ]

      child ->
        collect_child_errors(child.input_value.normalized, schema)
    end)
  end

  defp collect_child_errors(%Blueprint.Input.Value{normalized: norm}, schema) do
    collect_child_errors(norm, schema)
  end

  defp collect_child_errors(_node, _) do
    []
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t(), String.t()) :: Phase.Error.t()
  defp error(node, message) do
    %Phase.Error{
      phase: __MODULE__,
      message: message,
      locations: [node.source_location]
    }
  end

  def error_message(arg_name, inspected_value, verbose_errors \\ [])

  def error_message(arg_name, inspected_value, []) do
    ~s(Argument "#{arg_name}" has invalid value #{inspected_value}.)
  end

  def error_message(arg_name, inspected_value, verbose_errors) do
    error_message(arg_name, inspected_value) <> "\n" <> Enum.join(verbose_errors, "\n")
  end

  def value_error_message(id, expected_type_name, inspected_value) when is_integer(id) do
    ~s(In element ##{id + 1}: ) <>
      expected_type_error_message(expected_type_name, inspected_value)
  end

  def value_error_message(id, expected_type_name, inspected_value) do
    ~s(In field "#{id}": ) <> expected_type_error_message(expected_type_name, inspected_value)
  end

  def unknown_field_error_message(field_name) do
    ~s(In field "#{field_name}": Unknown field.)
  end

  defp expected_type_error_message(expected_type_name, inspected_value) do
    ~s(Expected type "#{expected_type_name}", found #{inspected_value}.)
  end
end
