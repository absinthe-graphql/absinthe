defmodule Absinthe.Phase.Document.Arguments.Parse do
  @moduledoc false

  # Parses Leaf Node inputs

  alias Absinthe.Blueprint.Input
  alias Absinthe.{Blueprint, Type}
  use Absinthe.Phase

  def run(input, options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, options[:context] || %{}))
    {:ok, result}
  end

  defp handle_node(%{normalized: nil} = node, _context) do
    node
  end

  defp handle_node(%Input.Value{normalized: normalized} = node, context) do
    case build_value(normalized, node.schema_node, context) do
      {:ok, value} ->
        %{node | data: value}

      :not_leaf_node ->
        node

      {:error, flag} ->
        %{node | normalized: normalized |> flag_invalid(flag)}

      {:error, flag, reason} ->
        normalized = normalized |> flag_invalid(flag, reason)
        %{node | normalized: normalized}
    end
  end

  defp handle_node(node, _context), do: node

  defp build_value(%Input.Null{}, %Type.NonNull{}, _) do
    {:error, :non_null}
  end

  defp build_value(%{__struct__: struct} = normalized, %Type.Scalar{} = schema_node, context)
       when struct in [Input.Boolean, Input.Float, Input.Integer, Input.String, Input.Null] do
    case Type.Scalar.parse(schema_node, normalized, context) do
      :error ->
        {:error, :bad_parse}

      {:error, reason} ->
        {:error, :bad_parse, reason}

      {:ok, val} ->
        {:ok, val}
    end
  end

  defp build_value(
         %Input.Object{} = normalized,
         %Type.Scalar{open_ended: true} = schema_node,
         context
       ) do
    case Type.Scalar.parse(schema_node, normalized, context) do
      :error ->
        {:error, :bad_parse}

      {:error, reason} ->
        {:error, :bad_parse, reason}

      {:ok, val} ->
        {:ok, val}
    end
  end

  defp build_value(_normalized, %Type.Scalar{}, _context) do
    {:error, :bad_parse}
  end

  defp build_value(%{value: value} = _normalized, nil = _schema_node, _context) do
    {:ok, value}
  end

  defp build_value(%Input.Null{}, %Type.Enum{}, _) do
    {:ok, nil}
  end

  defp build_value(normalized, %Type.Enum{} = schema_node, _) do
    case Type.Enum.parse(schema_node, normalized) do
      {:ok, %{value: value}} ->
        {:ok, value}

      :error ->
        {:error, :bad_parse}
    end
  end

  defp build_value(normalized, %Type.NonNull{of_type: inner_type}, context) do
    build_value(normalized, inner_type, context)
  end

  defp build_value(%{__struct__: struct}, %Type.InputObject{}, _)
       when struct in [Input.Boolean, Input.Float, Input.Integer, Input.String, Input.Enum] do
    {:error, :bad_parse}
  end

  defp build_value(_, _, _) do
    :not_leaf_node
  end
end
