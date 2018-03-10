defmodule Absinthe.Phase.Document.Validation.NoUnusedFragments do
  @moduledoc false

  # Validates document to ensure that all named fragments are used.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.operations))
    {:ok, result}
  end

  def handle_node(%Blueprint.Document.Fragment.Named{} = node, operations) do
    if uses?(node, operations) do
      node
    else
      node
      |> flag_invalid(:not_used)
      |> put_error(error(node))
    end
  end

  def handle_node(node, _) do
    node
  end

  @spec uses?(Blueprint.Document.Fragment.Named.t(), [Blueprint.Document.Operation.t()]) ::
          boolean
  defp uses?(node, operations) do
    Enum.any?(operations, &Blueprint.Document.Operation.uses?(&1, node))
  end

  # Generate the error for the node
  @spec error(Blueprint.Document.Fragment.Named.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate an error message for an unused fragment.
  """
  @spec error_message(String.t()) :: String.t()
  def error_message(name) do
    ~s(Fragment "#{name}" is never used.)
  end
end
