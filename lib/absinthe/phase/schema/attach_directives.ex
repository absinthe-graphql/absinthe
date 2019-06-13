defmodule Absinthe.Phase.Schema.AttachDirectives do
  @moduledoc false

  # Expand all directives in the document.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, options \\ []) do
    node =
      Blueprint.prewalk(
        input,
        &handle_node(&1, input.schema, Keyword.fetch!(options, :prototype_schema))
      )

    {:ok, node}
  end

  @spec handle_node(
          node :: Blueprint.Directive.t(),
          schema :: Absinthe.Schema.t(),
          proto_schema :: Absinthe.Schema.t()
        ) ::
          Blueprint.Directive.t()
  defp handle_node(%Blueprint.Directive{} = node, _schema, proto_schema) do
    schema_node = Absinthe.Schema.lookup_directive(proto_schema, node.name)
    %{node | schema_node: schema_node}
  end

  @spec handle_node(
          node :: Blueprint.node_t(),
          schema :: Absinthe.Schema.t(),
          proto_schema :: Absinthe.Schema.t()
        ) ::
          Blueprint.node_t()
  defp handle_node(node, _schema, _proto_schema) do
    node
  end
end
