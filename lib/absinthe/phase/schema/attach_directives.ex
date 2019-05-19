defmodule Absinthe.Phase.Schema.AttachDirectives do
  @moduledoc false

  # Expand all directives in the document.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &(handle_node(&1, input.schema)))
    {:ok, node}
  end

  @spec handle_node(node :: Blueprint.Directive.t(), schema :: Absinthe.Schema.t()) :: Blueprint.Directive.t()
  defp handle_node(%Blueprint.Directive{} = node, schema) do
    schema_node =
      Enum.find(available_directives(schema), &(&1.name == node.name))
    %{node | schema_node: schema_node}
  end

  @spec handle_node(node :: Blueprint.node_t(), schema :: Absinthe.Schema.t()) :: Blueprint.node_t()
  defp handle_node(node, _schema) do
    node
  end

  defp available_directives(schema) do
    schema.sdl_directives(builtins())
  end

  def builtins do
    [
      %Absinthe.Type.Directive{
        name: "deprecated",
        locations: [:field_definition, :input_field_definition, :argument_definition],
        expand: &expand_deprecate/2
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
