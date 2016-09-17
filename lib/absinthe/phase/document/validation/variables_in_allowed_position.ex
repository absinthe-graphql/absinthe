defmodule Absinthe.Phase.Document.Validation.VariablesInAllowedPosition do
  @moduledoc """
  Validates a variable is used in a position requiring the same type.
  """

  alias Absinthe.{Blueprint, Phase, Type, Schema}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  # TODO: Find all the literal uses of the variables and check it against the
  # expected type where it is assigned.

  defp handle_node(node, _) do
    node
  end

  # Generate the error
  @spec error(Blueprint.Document.Field.t, String.t) :: Phase.Error.t
  defp error(node, message) do
    Phase.Error.new(
      __MODULE__,
      message,
      node.source_location
    )
  end

  @doc """
  Generate the error message.
  """
  @spec error_message(String.t, String.t, String.t) :: String.t
  def error_message(variable_name, variable_type_name, position_type_name) do
    ~s(Variable "#{variable_name}" of type "#{variable_type_name}" used in position expecting type "#{position_type_name}".)
  end

end
