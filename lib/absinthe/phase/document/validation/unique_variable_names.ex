defmodule Absinthe.Phase.Document.Validation.UniqueVariableNames do
  @moduledoc false

  # Validates document to ensure that all variable definitions for an operation
  # have unique names.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    operations =
      for operation <- input.operations do
        variable_definitions =
          for variable <- operation.variable_definitions do
            process(variable, operation.variable_definitions)
          end

        %{operation | variable_definitions: variable_definitions}
      end

    result = %{input | operations: operations}
    {:ok, result}
  end

  @spec process(Blueprint.Document.VariableDefinition.t(), [
          Blueprint.Document.VariableDefinition.t()
        ]) :: Blueprint.Document.VariableDefinition.t()
  defp process(variable_definition, variable_definitions) do
    if duplicate?(variable_definitions, variable_definition) do
      variable_definition
      |> flag_invalid(:duplicate_name)
      |> put_error(error(variable_definition))
    else
      variable_definition
    end
  end

  # Whether a duplicate variable_definition is present
  @spec duplicate?(
          [Blueprint.Document.VariableDefinition.t()],
          Blueprint.Document.VariableDefinition.t()
        ) :: boolean
  defp duplicate?(variable_definitions, variable_definition) do
    Enum.count(variable_definitions, &(&1.name == variable_definition.name)) > 1
  end

  # Generate an error for a duplicate variable_definition.
  @spec error(Blueprint.Document.VariableDefinition.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate an error message for a duplicate variable definition.
  """
  @spec error_message(String.t()) :: String.t()
  def error_message(name) do
    ~s(There can only be one variable named "#{name}".)
  end
end
