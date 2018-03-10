defmodule Absinthe.Phase.Document.Validation.KnownFragmentNames do
  @moduledoc false

  # Validates document to ensure that only fragment spreads reference named
  # fragments that exist.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input))
    {:ok, result}
  end

  # Find the root and check for multiple anonymous operations
  @spec handle_node(Blueprint.node_t(), Blueprint.t()) :: Blueprint.node_t()
  defp handle_node(%Blueprint.Document.Fragment.Spread{} = node, blueprint) do
    case Blueprint.fragment(blueprint, node.name) do
      nil ->
        node
        |> flag_invalid(:bad_fragment_name)
        |> put_error(error(node))

      _ ->
        node
    end
  end

  defp handle_node(node, _) do
    node
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: ~s(Unknown fragment "#{node.name}"),
      locations: [node.source_location]
    }
  end
end
