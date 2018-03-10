defmodule Absinthe.Phase.Document.Validation.ProvidedNonNullVariables do
  @moduledoc false

  # Validates document to ensure that all non-null variable definitions
  # are provided values.

  alias Absinthe.{Blueprint, Phase, Schema}

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
  defp handle_node(
         %Blueprint.Document.VariableDefinition{
           type: %Blueprint.TypeReference.NonNull{},
           provided_value: nil
         } = node,
         _
       ) do
    node
    |> put_error(error(node))
  end

  defp handle_node(
         %Blueprint.Document.VariableDefinition{
           type: %Blueprint.TypeReference.NonNull{},
           provided_value: %Blueprint.Input.Null{}
         } = node,
         _
       ) do
    node
    |> put_error(error(node))
  end

  defp handle_node(node, _) do
    node
  end

  # Generate an error for variable definition
  @spec error(Blueprint.Document.VariableDefinition.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the error message.
  """
  @spec error_message(String.t()) :: String.t()
  def error_message(variable_name) do
    ~s(Variable "#{variable_name}": Expected non-null, found null.)
  end
end
