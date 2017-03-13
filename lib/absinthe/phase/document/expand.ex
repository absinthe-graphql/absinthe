defmodule Absinthe.Phase.Document.Expand do
  @moduledoc false

  alias Absinthe.Blueprint.Input
  alias Absinthe.{Blueprint}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    # By using a postwalk we can worry about leaf nodes first (scalars, enums),
    # and then for list and objects merely grab the data values.
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    # Blueprint.prewalk(result, fn
    #   %Absinthe.Blueprint.Document.Field{} = node ->
    #     IO.puts "--------------------"
    #     node.schema_node |> IO.inspect
    #     node.schema_node.type |> IO.inspect
    #   node ->
    #     node
    # end)
    {:ok, result}
  end
  #
  # def handle_info(%{schema_node: %{type: type}} = node, schema) do
  #   expand(node)
  # end
  # def handle_node(%{schema_node: type} = node, schema) do
  #   expand(node)
  # end
  def handle_node(%{schema_node: schema_node} = node, schema) do
    result = %{node | schema_node: expand(schema_node, schema)}
    result
  end
  def handle_node(node, _) do
    node
  end

  defp expand(%{type: type} = node, schema) do
    %{node | type: expand(type, schema)}
  end
  defp expand(%{of_type: type} = node, schema) do
    %{node | of_type: expand(type, schema)}
  end
  defp expand(type, schema) when is_atom(type) do
    schema
    |> Absinthe.Schema.lookup_type(type)
    |> expand(schema)
  end
  defp expand(type, _) do
    type
  end
end
