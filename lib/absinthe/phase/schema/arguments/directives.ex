defmodule Absinthe.Phase.Schema.Arguments.Directives do
  @moduledoc false

  # Set schema nodes for directive arguments

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  # Set provided value from the raw value
  defp handle_node(%Blueprint.Directive{schema_node: schema_node} = node)
       when not is_nil(schema_node) do
    args =
      for arg <- node.arguments do
        name = arg.name

        schema_node =
          Enum.find_value(node.schema_node.args || [], fn
            {_, %{name: ^name} = schema_arg} ->
              schema_arg

            _ ->
              false
          end)

        %{arg | schema_node: schema_node}
      end

    %{node | arguments: args}
  end

  # TODO: Set schema node on Absinthe.Blueprint.Input.String, etc

  defp handle_node(node) do
    node
  end
end
