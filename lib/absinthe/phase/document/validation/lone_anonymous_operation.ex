defmodule Absinthe.Phase.Document.Validation.LoneAnonymousOperation do
  @moduledoc false

  # Validates document to ensure that only one operation is provided without
  # a name.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  # Find the root and check for multiple anonymous operations
  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%Blueprint{} = node) do
    ops = process(node.operations)
    %{node | operations: ops}
  end

  defp handle_node(node) do
    node
  end

  @spec process([Blueprint.Document.Operation.t()]) :: [Blueprint.Document.Operation.t()]
  defp process(operations) do
    do_process(operations, length(operations))
  end

  @spec do_process([Blueprint.Document.Operation.t()], integer) :: [
          Blueprint.Document.Operation.t()
        ]
  defp do_process(operations, count) when count < 2 do
    operations
  end

  defp do_process(operations, _) do
    Enum.map(operations, fn
      %{name: nil} = op ->
        flag_invalid(op, :bad_name)
        |> put_error(error(op))

      other ->
        other
    end)
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: "This anonymous operation must be the only defined operation.",
      locations: [node.source_location]
    }
  end
end
