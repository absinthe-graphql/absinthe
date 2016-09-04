defmodule Absinthe.Phase.Validation.KnownDirectives do

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.postwalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Directive{schema_node: nil} = node) do
    node
    |> put_error(error_unknown(node))
    |> flag_invalid(:no_schema_node)
    |> IO.inspect
  end
  defp handle_node(%Blueprint.Directive{} = node) do
    node
  end
  defp handle_node(%{directives: directives} = node) do
    inherit_invalid(node, directives, :bad_directive)
  end
  defp handle_node(node) do
    node
  end

  # Generate the error for the node
  @spec error_unknown(Blueprint.node_t) :: Phase.Error.t
  defp error_unknown(node) do
    Phase.Error.new(
      __MODULE__,
      "Unknown directive.",
      node.source_location
    )
  end

  @spec error_misplaced(Blueprint.node_t, String.t) :: Phase.Error.t
  defp error_misplaced(node, placement) do
    Phase.Error.new(
      __MODULE__,
      "May not be placed on #{placement}.",
      node.source_location
    )
  end

end
