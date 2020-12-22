defmodule Absinthe.Phase.Document.Validation.RepeatableDirectives do
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

  defp handle_node(%Blueprint.Directive{} = node) do
    node
  end

  defp handle_node(%{directives: []} = node) do
    node
  end

  defp handle_node(%{directives: _} = node) do
    node
    |> check_directives
    |> inherit_invalid(node.directives, :bad_directive)
  end

  defp handle_node(node) do
    node
  end

  defp check_directives(node) do
    directives =
      for directive <- node.directives do
        case directive do
          %{schema_node: nil} ->
            directive

          %{schema_node: %{repeatable: true}} ->
            directive

          directive ->
            check_duplicates(
              directive,
              Enum.filter(
                node.directives,
                &compare_directive_schema_node(directive.schema_node, &1.schema_node)
              )
            )
        end
      end

    %{node | directives: directives}
  end

  defp compare_directive_schema_node(_, nil), do: false

  defp compare_directive_schema_node(%{identifier: identifier}, %{identifier: identifier}),
    do: true

  defp compare_directive_schema_node(_, _), do: false

  # Generate the error for the node
  @spec error_repeated(Blueprint.node_t()) :: Phase.Error.t()
  defp error_repeated(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: "Directive `#{node.name}' cannot be applied repeatedly.",
      locations: [node.source_location]
    }
  end

  defp check_duplicates(directive, [_single]) do
    directive
  end

  defp check_duplicates(directive, _multiple) do
    directive
    |> flag_invalid(:duplicate_directive)
    |> put_error(error_repeated(directive))
  end
end
