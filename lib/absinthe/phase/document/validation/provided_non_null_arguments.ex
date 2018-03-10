defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullArguments do
  @moduledoc false

  # Validates document to ensure that all non-null arguments are provided.

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t(), Schema.t()) :: Blueprint.node_t()
  # Missing Arguments
  defp handle_node(%Blueprint.Input.Argument{value: nil, flags: %{missing: _}} = node, schema) do
    node = node |> put_error(error(node, node.schema_node.type, schema))
    {:halt, node}
  end

  defp handle_node(node, _) do
    node
  end

  # Generate the error for this validation
  @spec error(Blueprint.node_t(), Type.t(), Schema.t()) :: Phase.Error.t()
  defp error(node, type, schema) do
    type_name = Type.name(type, schema)

    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name, type_name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the argument error.
  """
  @spec error_message(String.t(), String.t()) :: String.t()
  def error_message(name, type_name) do
    ~s(In argument "#{name}": Expected type "#{type_name}", found null.)
  end
end
