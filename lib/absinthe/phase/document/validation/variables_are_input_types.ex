defmodule Absinthe.Phase.Document.Validation.VariablesAreInputTypes do
  @moduledoc false

  # Validates document to ensure that all variable definitions are for
  # input types.

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  # Find variable definitions
  @spec handle_node(Blueprint.node_t(), Schema.t()) :: Blueprint.node_t()
  defp handle_node(%Blueprint.Document.VariableDefinition{schema_node: nil} = node, _) do
    node
  end

  defp handle_node(%Blueprint.Document.VariableDefinition{} = node, schema) do
    type = Schema.lookup_type(schema, node.schema_node)

    if Type.input_type?(Type.unwrap(type)) do
      node
    else
      node
      |> flag_invalid(:non_input_type)
      |> put_error(error(node, Type.name(node.schema_node)))
    end
  end

  defp handle_node(node, _) do
    node
  end

  # Generate an error for an input field
  @spec error(Blueprint.Document.VariableDefinition.t(), String.t()) :: Phase.Error.t()
  defp error(node, type_rep) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name, type_rep),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the error message.
  """
  @spec error_message(String.t(), String.t()) :: String.t()
  def error_message(variable_name, type_rep) do
    ~s(Variable "#{variable_name}" cannot be non-input type "#{type_rep}".)
  end
end
