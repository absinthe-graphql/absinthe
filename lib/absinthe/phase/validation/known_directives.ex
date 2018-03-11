defmodule Absinthe.Phase.Validation.KnownDirectives do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.postwalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Directive{schema_node: nil} = node) do
    node
    |> put_error(error_unknown(node))
  end

  defp handle_node(%Blueprint.Directive{} = node) do
    node
  end

  defp handle_node(%{directives: []} = node) do
    node
  end

  defp handle_node(%{directives: _} = node) do
    check_directives(node)
    |> inherit_invalid(node.directives, :bad_directive)
  end

  defp handle_node(node) do
    node
  end

  defp check_directives(node) do
    placement = Blueprint.Directive.placement(node)

    directives =
      for directive <- node.directives do
        if directive.schema_node do
          if placement in directive.schema_node.locations do
            directive
          else
            directive
            |> put_error(error_misplaced(directive, placement))
            |> flag_invalid(:bad_placement)
          end
        else
          directive
        end
      end

    %{node | directives: directives}
  end

  # Generate the error for the node
  @spec error_unknown(Blueprint.node_t()) :: Phase.Error.t()
  defp error_unknown(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: "Unknown directive.",
      locations: [node.source_location]
    }
  end

  @spec error_misplaced(Blueprint.node_t(), atom) :: Phase.Error.t()
  defp error_misplaced(node, placement) do
    placement_name = placement |> to_string |> String.upcase()

    %Phase.Error{
      phase: __MODULE__,
      message: "May not be used on #{placement_name}.",
      locations: [node.source_location]
    }
  end
end
