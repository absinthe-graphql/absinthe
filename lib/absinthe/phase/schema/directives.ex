defmodule Absinthe.Phase.Schema.Directives do
  @moduledoc false

  # Expand all directives in the document.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%{directives: directives} = node) do
    Enum.reduce(directives, node, fn directive, acc ->
      Blueprint.Directive.expand(directive, acc)
    end)
  end

  defp handle_node(node) do
    node
  end

  def available_directives do
    [
      %Absinthe.Type.Directive{
        name: "deprecated",
        locations: [:field_definition, :input_field_definition, :argument_definition],
        expand: {:ref, __MODULE__, :expand_deprecate}
      }
    ]
  end

  @doc """
  Add a deprecation (with an optional reason) to a node.
  """
  @spec expand_deprecate(arguments :: %{optional(:reason) => String.t()}, node :: Blueprint.node_t()) :: Blueprint.node_t()
  def expand_deprecate(arguments, node) do
    %{node | deprecation: %Absinthe.Type.Deprecation{reason: arguments[:reason]}}
  end

end
